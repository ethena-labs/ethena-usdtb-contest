// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

/* solhint-disable private-vars-leading-underscore */
/* solhint-disable var-name-mixedcase */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "./IUSDtbMinting.sol";
import "./IUSDtb.sol";
import "../SingleAdminAccessControl.sol";

/**
 * @title USDtb Minting
 * @notice This contract mints and redeems USDtb, the RWA stablecoin backed by tokenized treasuries
 */
contract USDtbMinting is IUSDtbMinting, SingleAdminAccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  /* --------------- CONSTANTS --------------- */

  /// @notice EIP712 domain
  bytes32 private constant EIP712_DOMAIN =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  /// @notice order type
  bytes32 private constant ORDER_TYPE = keccak256(
    "Order(string order_id,uint8 order_type,uint120 expiry,uint128 nonce,address benefactor,address beneficiary,address collateral_asset,uint128 collateral_amount,uint128 usdtb_amount)"
  );

  /// @notice role enabling to invoke mint
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @notice role enabling to invoke redeem
  bytes32 private constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

  /// @notice role enabling to transfer collateral to custody wallets
  bytes32 private constant COLLATERAL_MANAGER_ROLE = keccak256("COLLATERAL_MANAGER_ROLE");

  /// @notice role enabling to disable mint and redeem and remove minters and redeemers in an emergency
  bytes32 private constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");

  /// @notice EIP 1271 magic value hash
  bytes4 private constant EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

  /// @notice address denoting native ether
  address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice EIP712 name
  bytes32 private constant EIP_712_NAME = keccak256("USDtbMinting");

  /// @notice holds EIP712 revision
  bytes32 private constant EIP712_REVISION = keccak256("1");

  /// @notice required ratio for route
  uint128 private constant ROUTE_REQUIRED_RATIO = 10_000;

  /// @notice stablecoin price ratio multiplier
  uint128 private constant STABLES_RATIO_MULTIPLIER = 10000;

  /* --------------- STATE VARIABLES --------------- */

  /// @notice USDtb stablecoin
  IUSDtb public usdtb;

  // @notice whitelisted benefactors
  EnumerableSet.AddressSet private _whitelistedBenefactors;

  // @notice approved beneficiaries for a given benefactor
  mapping(address => EnumerableSet.AddressSet) private _approvedBeneficiariesPerBenefactor;

  // @notice custodian addresses
  EnumerableSet.AddressSet private _custodianAddresses;

  /// @notice holds computable chain id
  uint256 private immutable _chainId;

  /// @notice holds computable domain separator
  bytes32 private immutable _domainSeparator;

  /// @notice user deduplication
  mapping(address => mapping(uint256 => uint256)) private _orderBitmaps;

  /// @notice For smart contracts to delegate signing to EOA address
  mapping(address => mapping(address => DelegatedSignerStatus)) public delegatedSigner;

  // @notice the allowed price delta in bps for stablecoin minting
  uint128 public stablesDeltaLimit;

  /// @notice global single block totals
  GlobalConfig public globalConfig;

  /// @notice running total USDtb minted/redeemed per single block
  mapping(uint256 => BlockTotals) public totalPerBlock;

  /// @notice total USDtb that can be minted/redeemed across all assets per single block.
  mapping(uint256 => mapping(address => BlockTotals)) public totalPerBlockPerAsset;

  /// @notice configurations per token asset
  mapping(address => TokenConfig) public tokenConfig;

  /* --------------- MODIFIERS --------------- */

  /// @notice ensure that the already minted USDtb in the actual block plus the amount to be minted is below the maximum mint amount
  /// @param mintAmount The USDtb amount to be minted
  /// @param asset The asset to be minted
  modifier belowMaxMintPerBlock(uint128 mintAmount, address asset) {
    TokenConfig memory _config = tokenConfig[asset];
    if (!_config.isActive) revert UnsupportedAsset();
    if (totalPerBlockPerAsset[block.number][asset].mintedPerBlock + mintAmount > _config.maxMintPerBlock) {
      revert MaxMintPerBlockExceeded();
    }
    _;
  }

  /// @notice ensure that the already redeemed USDtb in the actual block plus the amount to be redeemed is below the maximum redeem amount
  /// @param redeemAmount The USDtb amount to be redeemed
  /// @param asset The asset to be redeemed
  modifier belowMaxRedeemPerBlock(uint128 redeemAmount, address asset) {
    TokenConfig memory _config = tokenConfig[asset];
    if (!_config.isActive) revert UnsupportedAsset();
    if (totalPerBlockPerAsset[block.number][asset].redeemedPerBlock + redeemAmount > _config.maxRedeemPerBlock) {
      revert MaxRedeemPerBlockExceeded();
    }
    _;
  }

  /// @notice ensure that the global, overall minted USDtb in the actual block
  /// @notice plus the amount to be minted is below globalMaxMintPerBlock
  /// @param mintAmount The USDtb amount to be minted
  modifier belowGlobalMaxMintPerBlock(uint128 mintAmount) {
    uint128 totalMintedThisBlock = totalPerBlock[uint128(block.number)].mintedPerBlock;
    if (totalMintedThisBlock + mintAmount > globalConfig.globalMaxMintPerBlock) revert GlobalMaxMintPerBlockExceeded();
    _;
  }

  /// @notice ensure that the global, overall redeemed USDtb in the actual block
  /// @notice plus the amount to be redeemed is below globalMaxRedeemPerBlock
  /// @param redeemAmount The USDtb amount to be redeemed
  modifier belowGlobalMaxRedeemPerBlock(uint128 redeemAmount) {
    uint128 totalRedeemedThisBlock = totalPerBlock[block.number].redeemedPerBlock;
    if (totalRedeemedThisBlock + redeemAmount > globalConfig.globalMaxRedeemPerBlock) {
      revert GlobalMaxRedeemPerBlockExceeded();
    }
    _;
  }

  /* --------------- CONSTRUCTOR --------------- */

  constructor(
    address[] memory _assets,
    TokenConfig[] memory _tokenConfig,
    GlobalConfig memory _globalConfig,
    address[] memory _custodians,
    address _admin
  ) ReentrancyGuard() {
    if (_tokenConfig.length == 0) revert NoAssetsProvided();
    if (_assets.length == 0) revert NoAssetsProvided();
    if (_admin == address(0)) revert InvalidZeroAddress();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    // Ensure every token config has an asset key
    if (_tokenConfig.length != _assets.length) {
      revert InvalidAssetAddress();
    }

    for (uint128 j = 0; j < _custodians.length;) {
      addCustodianAddress(_custodians[j]);
      unchecked {
        ++j;
      }
    }

    // Set the global max USDtb mint/redeem limits
    globalConfig = _globalConfig;

    // Set the max mint/redeem limits per block for each asset
    for (uint128 k = 0; k < _tokenConfig.length;) {
      if (tokenConfig[_assets[k]].isActive || _assets[k] == address(0)) {
        revert InvalidAssetAddress();
      }
      _setTokenConfig(_assets[k], _tokenConfig[k]);
      unchecked {
        ++k;
      }
    }

    if (msg.sender != _admin) {
      _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    _chainId = block.chainid;
    _domainSeparator = _computeDomainSeparator();
  }

  /* --------------- EXTERNAL --------------- */

  /**
   * @notice Fallback function to receive ether
   */
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * @notice Mint stablecoins from assets
   * @param order struct containing order details and confirmation from server
   * @param signature signature of the taker
   */
  function mint(Order calldata order, Route calldata route, Signature calldata signature)
    external
    override
    nonReentrant
    onlyRole(MINTER_ROLE)
    belowMaxMintPerBlock(order.usdtb_amount, order.collateral_asset)
    belowGlobalMaxMintPerBlock(order.usdtb_amount)
  {
    if (order.order_type != OrderType.MINT) revert InvalidOrder();
    verifyOrder(order, signature);
    if (!verifyRoute(route)) revert InvalidRoute();
    _deduplicateOrder(order.benefactor, order.nonce);
    // Add to the minted amount in this block
    totalPerBlockPerAsset[block.number][order.collateral_asset].mintedPerBlock += order.usdtb_amount;
    totalPerBlock[block.number].mintedPerBlock += order.usdtb_amount;
    _transferCollateral(
      order.collateral_amount, order.collateral_asset, order.benefactor, route.addresses, route.ratios
    );
    usdtb.mint(order.beneficiary, order.usdtb_amount);
    emit Mint(
      order.order_id,
      order.benefactor,
      order.beneficiary,
      msg.sender,
      order.collateral_asset,
      order.collateral_amount,
      order.usdtb_amount
    );
  }

  /**
   * @notice Redeem stablecoins for assets
   * @param order struct containing order details and confirmation from server
   * @param signature signature of the taker
   */
  function redeem(Order calldata order, Signature calldata signature)
    external
    override
    nonReentrant
    onlyRole(REDEEMER_ROLE)
    belowMaxRedeemPerBlock(order.usdtb_amount, order.collateral_asset)
    belowGlobalMaxRedeemPerBlock(order.usdtb_amount)
  {
    if (order.order_type != OrderType.REDEEM) revert InvalidOrder();
    verifyOrder(order, signature);
    _deduplicateOrder(order.benefactor, order.nonce);
    // Add to the redeemed amount in this block
    totalPerBlockPerAsset[block.number][order.collateral_asset].redeemedPerBlock += order.usdtb_amount;
    totalPerBlock[block.number].redeemedPerBlock += order.usdtb_amount;
    usdtb.burnFrom(order.benefactor, order.usdtb_amount);
    _transferToBeneficiary(order.beneficiary, order.collateral_asset, order.collateral_amount);
    emit Redeem(
      order.order_id,
      order.benefactor,
      order.beneficiary,
      msg.sender,
      order.collateral_asset,
      order.collateral_amount,
      order.usdtb_amount
    );
  }

  /// @notice Sets the overall, global maximum USDtb mint size per block
  function setGlobalMaxMintPerBlock(uint128 _globalMaxMintPerBlock) external onlyRole(DEFAULT_ADMIN_ROLE) {
    globalConfig.globalMaxMintPerBlock = _globalMaxMintPerBlock;
    emit GlobalMaxMintPerBlock(msg.sender, _globalMaxMintPerBlock);
  }

  /// @notice Sets the overall, global maximum USDtb redeem size per block
  function setGlobalMaxRedeemPerBlock(uint128 _globalMaxRedeemPerBlock) external onlyRole(DEFAULT_ADMIN_ROLE) {
    globalConfig.globalMaxRedeemPerBlock = _globalMaxRedeemPerBlock;
    emit GlobalMaxRedeemPerBlock(msg.sender, _globalMaxRedeemPerBlock);
  }

  /// @notice Disables the mint and redeem
  function disableMintRedeem() external onlyRole(GATEKEEPER_ROLE) {
    globalConfig.globalMaxMintPerBlock = 0;
    globalConfig.globalMaxRedeemPerBlock = 0;
    emit DisableMintRedeem(msg.sender);
  }

  /// @notice Enables smart contracts to delegate an address for signing
  function setDelegatedSigner(address _delegateTo) external {
    delegatedSigner[_delegateTo][msg.sender] = DelegatedSignerStatus.PENDING;
    emit DelegatedSignerInitiated(_delegateTo, msg.sender);
  }

  /// @notice The delegated address to confirm delegation
  function confirmDelegatedSigner(address _delegatedBy) external {
    if (delegatedSigner[msg.sender][_delegatedBy] != DelegatedSignerStatus.PENDING) {
      revert DelegationNotInitiated();
    }
    delegatedSigner[msg.sender][_delegatedBy] = DelegatedSignerStatus.ACCEPTED;
    emit DelegatedSignerAdded(msg.sender, _delegatedBy);
  }

  /// @notice Enables smart contracts to undelegate an address for signing
  function removeDelegatedSigner(address _removedSigner) external {
    delegatedSigner[_removedSigner][msg.sender] = DelegatedSignerStatus.REJECTED;
    emit DelegatedSignerRemoved(_removedSigner, msg.sender);
  }

  /// @notice transfers an asset to a custody wallet
  function transferToCustody(address wallet, address asset, uint128 amount)
    external
    nonReentrant
    onlyRole(COLLATERAL_MANAGER_ROLE)
  {
    if (wallet == address(0) || !_custodianAddresses.contains(wallet)) revert InvalidAddress();
    if (asset == NATIVE_TOKEN) {
      (bool success,) = wallet.call{value: amount}("");
      if (!success) revert TransferFailed();
    } else {
      IERC20(asset).safeTransfer(wallet, amount);
    }
    emit CustodyTransfer(wallet, asset, amount);
  }

  /// @notice Removes an asset from the supported assets list
  function removeSupportedAsset(address asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!tokenConfig[asset].isActive) revert InvalidAssetAddress();
    delete tokenConfig[asset];
    emit AssetRemoved(asset);
  }

  /// @notice Checks if an asset is supported.
  function isSupportedAsset(address asset) external view returns (bool) {
    return tokenConfig[asset].isActive;
  }

  /// @notice Removes an custodian from the custodian address list
  function removeCustodianAddress(address custodian) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!_custodianAddresses.remove(custodian)) revert InvalidCustodianAddress();
    emit CustodianAddressRemoved(custodian);
  }

  /// @notice Removes the minter role from an account, this can ONLY be executed by the gatekeeper role
  /// @param minter The address to remove the minter role from
  function removeMinterRole(address minter) external onlyRole(GATEKEEPER_ROLE) {
    _revokeRole(MINTER_ROLE, minter);
  }

  /// @notice Removes the redeemer role from an account, this can ONLY be executed by the gatekeeper role
  /// @param redeemer The address to remove the redeemer role from
  function removeRedeemerRole(address redeemer) external onlyRole(GATEKEEPER_ROLE) {
    _revokeRole(REDEEMER_ROLE, redeemer);
  }

  /// @notice Removes the collateral manager role from an account, this can ONLY be executed by the gatekeeper role
  /// @param collateralManager The address to remove the collateralManager role from
  function removeCollateralManagerRole(address collateralManager) external onlyRole(GATEKEEPER_ROLE) {
    _revokeRole(COLLATERAL_MANAGER_ROLE, collateralManager);
  }

  /// @notice Removes the benefactor address from the benefactor whitelist
  function removeWhitelistedBenefactor(address benefactor) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!_whitelistedBenefactors.remove(benefactor)) revert InvalidAddress();
    emit BenefactorRemoved(benefactor);
  }

  /* --------------- PUBLIC --------------- */

  /// @notice Adds an custodian to the supported custodians list.
  function addCustodianAddress(address custodian) public onlyRole(DEFAULT_ADMIN_ROLE) {
    if (custodian == address(0) || custodian == address(usdtb) || !_custodianAddresses.add(custodian)) {
      revert InvalidCustodianAddress();
    }
    emit CustodianAddressAdded(custodian);
  }

  /// @notice Adds a benefactor address to the benefactor whitelist
  function addWhitelistedBenefactor(address benefactor) public onlyRole(DEFAULT_ADMIN_ROLE) {
    if (benefactor == address(0) || !_whitelistedBenefactors.add(benefactor)) {
      revert InvalidBenefactorAddress();
    }
    emit BenefactorAdded(benefactor);
  }

  /// @notice Adds a beneficiary address to the approved beneficiaries list.
  /// @notice Only the benefactor can add or remove corresponding beneficiaries
  /// @param beneficiary The beneficiary address
  /// @param status The status of the beneficiary, true to be added, false to be removed.
  function setApprovedBeneficiary(address beneficiary, bool status) public {
    if (status) {
      if (!_approvedBeneficiariesPerBenefactor[msg.sender].add(beneficiary)) {
        revert InvalidBeneficiaryAddress();
      } else {
        emit BeneficiaryAdded(msg.sender, beneficiary);
      }
    } else {
      if (!_approvedBeneficiariesPerBenefactor[msg.sender].remove(beneficiary)) {
        revert InvalidBeneficiaryAddress();
      } else {
        emit BeneficiaryRemoved(msg.sender, beneficiary);
      }
    }
  }

  /// @notice Get the domain separator for the token
  /// @dev Return cached value if chainId matches cache, otherwise recomputes separator, to prevent replay attack across forks
  /// @return The domain separator of the token at current chain
  function getDomainSeparator() public view returns (bytes32) {
    if (block.chainid == _chainId) {
      return _domainSeparator;
    }
    return _computeDomainSeparator();
  }

  /// @notice hash an Order struct
  function hashOrder(Order calldata order) public view override returns (bytes32) {
    return ECDSA.toTypedDataHash(getDomainSeparator(), keccak256(encodeOrder(order)));
  }

  function encodeOrder(Order calldata order) public pure returns (bytes memory) {
    return abi.encode(
      ORDER_TYPE,
      keccak256(bytes(order.order_id)),
      order.order_type,
      order.expiry,
      order.nonce,
      order.benefactor,
      order.beneficiary,
      order.collateral_asset,
      order.collateral_amount,
      order.usdtb_amount
    );
  }

  /// @notice assert validity of signed order
  function verifyOrder(Order calldata order, Signature calldata signature)
    public
    view
    override
    returns (bytes32 taker_order_hash)
  {
    taker_order_hash = hashOrder(order);
    if (signature.signature_type == SignatureType.EIP712) {
      address signer = ECDSA.recover(taker_order_hash, signature.signature_bytes);
      if (!(signer == order.benefactor || delegatedSigner[signer][order.benefactor] == DelegatedSignerStatus.ACCEPTED))
      {
        revert InvalidEIP712Signature();
      }
    } else if (signature.signature_type == SignatureType.EIP1271) {
      if (
        IERC1271(order.benefactor).isValidSignature(taker_order_hash, signature.signature_bytes) != EIP1271_MAGICVALUE
      ) {
        revert InvalidEIP1271Signature();
      }
    } else {
      revert UnknownSignatureType();
    }
    if (!_whitelistedBenefactors.contains(order.benefactor)) {
      revert BenefactorNotWhitelisted();
    }
    if (order.benefactor != order.beneficiary) {
      if (!_approvedBeneficiariesPerBenefactor[order.benefactor].contains(order.beneficiary)) {
        revert BeneficiaryNotApproved();
      }
    }
    TokenType typeOfToken = tokenConfig[order.collateral_asset].tokenType;
    if (typeOfToken == TokenType.STABLE) {
      if (!verifyStablesLimit(order.collateral_amount, order.usdtb_amount, order.collateral_asset, order.order_type)) {
        revert InvalidStablePrice();
      }
    }
    if (order.beneficiary == address(0)) revert InvalidAddress();
    if (order.collateral_amount == 0 || order.usdtb_amount == 0) revert InvalidAmount();
    if (block.timestamp > order.expiry) revert SignatureExpired();
  }

  /// @notice assert validity of route object per type
  function verifyRoute(Route calldata route) public view override returns (bool) {
    uint128 totalRatio = 0;
    if (route.addresses.length != route.ratios.length) {
      return false;
    }
    if (route.addresses.length == 0) {
      return false;
    }
    for (uint128 i = 0; i < route.addresses.length;) {
      if (!_custodianAddresses.contains(route.addresses[i]) || route.addresses[i] == address(0) || route.ratios[i] == 0)
      {
        return false;
      }
      totalRatio += route.ratios[i];
      unchecked {
        ++i;
      }
    }
    return (totalRatio == ROUTE_REQUIRED_RATIO);
  }

  /// @notice verify validity of nonce by checking its presence
  function verifyNonce(address sender, uint128 nonce) public view override returns (uint128, uint256, uint256) {
    if (nonce == 0) revert InvalidNonce();
    uint128 invalidatorSlot = uint64(nonce) >> 8;
    uint256 invalidatorBit = 1 << uint8(nonce);
    uint256 invalidator = _orderBitmaps[sender][invalidatorSlot];
    if (invalidator & invalidatorBit != 0) revert InvalidNonce();

    return (invalidatorSlot, invalidator, invalidatorBit);
  }

  function verifyStablesLimit(
    uint128 collateralAmount,
    uint128 usdtbAmount,
    address collateralAsset,
    OrderType orderType
  ) public view returns (bool) {
    uint128 usdtbDecimals = _getDecimals(address(usdtb));
    uint128 collateralDecimals = _getDecimals(collateralAsset);

    uint128 normalizedCollateralAmount;
    uint128 scale = uint128(
      usdtbDecimals > collateralDecimals
        ? 10 ** (usdtbDecimals - collateralDecimals)
        : 10 ** (collateralDecimals - usdtbDecimals)
    );

    normalizedCollateralAmount = usdtbDecimals > collateralDecimals ? collateralAmount * scale : collateralAmount / scale;

    uint128 difference = normalizedCollateralAmount > usdtbAmount
      ? normalizedCollateralAmount - usdtbAmount
      : usdtbAmount - normalizedCollateralAmount;

    uint128 differenceInBps = (difference * STABLES_RATIO_MULTIPLIER) / usdtbAmount;

    if (orderType == OrderType.MINT) {
      return usdtbAmount > normalizedCollateralAmount ? differenceInBps <= stablesDeltaLimit : true;
    } else {
      return normalizedCollateralAmount > usdtbAmount ? differenceInBps <= stablesDeltaLimit : true;
    }
  }

  /* --------------- PRIVATE --------------- */

  /// @notice deduplication of taker order
  function _deduplicateOrder(address sender, uint128 nonce) private {
    (uint128 invalidatorSlot, uint256 invalidator, uint256 invalidatorBit) = verifyNonce(sender, nonce);
    _orderBitmaps[sender][invalidatorSlot] = invalidator | invalidatorBit;
  }

  /* --------------- INTERNAL --------------- */

  /// @notice transfer supported asset to beneficiary address
  function _transferToBeneficiary(address beneficiary, address asset, uint128 amount) internal {
    if (asset == NATIVE_TOKEN) {
      if (address(this).balance < amount) revert InvalidAmount();
      (bool success,) = (beneficiary).call{value: amount}("");
      if (!success) revert TransferFailed();
    } else {
      IERC20(asset).safeTransfer(beneficiary, amount);
    }
  }

  /// @notice transfer supported asset to array of custody addresses per defined ratio
  function _transferCollateral(
    uint128 amount,
    address asset,
    address benefactor,
    address[] calldata addresses,
    uint128[] calldata ratios
  ) internal {
    // cannot mint using unsupported asset or native ETH even if it is supported for redemptions
    if (!tokenConfig[asset].isActive || asset == NATIVE_TOKEN) revert UnsupportedAsset();
    IERC20 token = IERC20(asset);
    uint128 totalTransferred = 0;
    for (uint128 i = 0; i < addresses.length;) {
      uint128 amountToTransfer = (amount * ratios[i]) / ROUTE_REQUIRED_RATIO;
      token.safeTransferFrom(benefactor, addresses[i], amountToTransfer);
      totalTransferred += amountToTransfer;
      unchecked {
        ++i;
      }
    }
    uint128 remainingBalance = amount - totalTransferred;
    if (remainingBalance > 0) {
      token.safeTransferFrom(benefactor, addresses[addresses.length - 1], remainingBalance);
    }
  }

  function _setTokenConfig(address asset, TokenConfig memory _tokenConfig) internal {
    if (_tokenConfig.maxMintPerBlock == 0 || _tokenConfig.maxRedeemPerBlock == 0) {
      revert InvalidAmount();
    }
    _tokenConfig.isActive = true;
    tokenConfig[asset] = _tokenConfig;
  }

  function addSupportedAsset(address asset, TokenConfig memory _tokenConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (tokenConfig[asset].isActive || asset == address(0) || asset == address(usdtb)) {
      revert InvalidAssetAddress();
    }
    _setTokenConfig(asset, _tokenConfig);
    emit AssetAdded(asset);
  }

  function setMaxMintPerBlock(uint128 _maxMintPerBlock, address asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setMaxMintPerBlock(_maxMintPerBlock, asset);
  }

  function _setMaxMintPerBlock(uint128 _maxMintPerBlock, address asset) internal {
    uint128 oldMaxMintPerBlock = tokenConfig[asset].maxMintPerBlock;
    tokenConfig[asset].maxMintPerBlock = _maxMintPerBlock;
    emit MaxMintPerBlockChanged(oldMaxMintPerBlock, _maxMintPerBlock, asset);
  }

  function setMaxRedeemPerBlock(uint128 _maxRedeemPerBlock, address asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setMaxRedeemPerBlock(_maxRedeemPerBlock, asset);
  }

  /// @notice Sets the max redeemPerBlock limit for a given asset
  function _setMaxRedeemPerBlock(uint128 _maxRedeemPerBlock, address asset) internal {
    uint128 oldMaxRedeemPerBlock = tokenConfig[asset].maxRedeemPerBlock;
    tokenConfig[asset].maxRedeemPerBlock = _maxRedeemPerBlock;
    emit MaxRedeemPerBlockChanged(oldMaxRedeemPerBlock, _maxRedeemPerBlock, asset);
  }

  /// @notice Compute the current domain separator
  /// @return The domain separator for the token
  function _computeDomainSeparator() internal view returns (bytes32) {
    return keccak256(abi.encode(EIP712_DOMAIN, EIP_712_NAME, EIP712_REVISION, block.chainid, address(this)));
  }

  // @notice Set the token type for a given token
  function setTokenType(address asset, TokenType tokenType) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!tokenConfig[asset].isActive) revert UnsupportedAsset();
    tokenConfig[asset].tokenType = tokenType;
    emit TokenTypeSet(asset, uint256(tokenType));
  }

  /// @notice set the allowed price delta in bps for stablecoin minting
  function setStablesDeltaLimit(uint128 _stablesDeltaLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
    stablesDeltaLimit = _stablesDeltaLimit;
  }

  /// @notice set the USDtb token address
  function setUSDtbToken(IUSDtb _usdtb) external onlyRole(DEFAULT_ADMIN_ROLE) {
    usdtb = _usdtb;
    emit USDtbSet(address(_usdtb));
  }

  /// @notice get the decimals of a token
  function _getDecimals(address token) internal view returns (uint128) {
    uint8 decimals = IERC20Metadata(token).decimals();
    return uint128(decimals);
  }

  /* --------------- GETTERS --------------- */

  /// @notice returns whether an address is a custodian
  function isCustodianAddress(address custodian) public view returns (bool) {
    return _custodianAddresses.contains(custodian);
  }

  /// @notice returns whether an address is a whitelisted benefactor
  function isWhitelistedBenefactor(address benefactor) public view returns (bool) {
    return _whitelistedBenefactors.contains(benefactor);
  }

  /// @notice returns whether an address is a approved beneficiary per benefactor
  function isApprovedBeneficiary(address benefactor, address beneficiary) public view returns (bool) {
    return _approvedBeneficiariesPerBenefactor[benefactor].contains(beneficiary);
  }
}
