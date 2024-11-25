// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable private-vars-leading-underscore  */
/* solhint-disable func-name-mixedcase  */
/* solhint-disable var-name-mixedcase  */

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {SigUtils} from "../utils/SigUtils.sol";
import {Vm} from "forge-std/Vm.sol";
import {Utils} from "../utils/Utils.sol";
import {Upgrades} from "../../contracts/lib/Upgrades.sol";

import "../../contracts/mock/MockToken.sol";
import "../../contracts/usdtb/USDtb.sol";
import "../../contracts/usdtb/IUSDtbMinting.sol";
import "../../contracts/usdtb/IUSDtbMintingEvents.sol";
import "../../contracts/usdtb/USDtbMinting.sol";
import "../../contracts/interfaces/ISingleAdminAccessControl.sol";
import "../../contracts/usdtb/IUSDtbDefinitions.sol";
import "../../contracts/mock/MockMultisigWallet.sol";
import "../../contracts/usdtb/IUSDtbDefinitions.sol";

contract USDtbMintingBaseSetup is Test, IUSDtbMintingEvents, IUSDtbDefinitions {
  Utils internal utils;

  struct USDtbDeploymentAddresses {
    address proxyAddress;
    address USDtbImplementation;
    address admin;
    address proxyAdminAddress;
  }

  USDtb internal usdtbToken;
  USDtbDeploymentAddresses internal USDtbDeploymentAddressesInstance;
  ITransparentUpgradeableProxy internal USDtbContractAsProxy;
  ProxyAdmin proxyAdminContract;

  MockToken internal stETHToken;
  MockToken internal cbETHToken;
  MockToken internal rETHToken;
  MockToken internal USDCToken;
  MockToken internal USDTToken;
  MockToken internal token;
  USDtbMinting internal USDtbMintingContract;
  MockMultiSigWallet internal MultiSigWalletBenefactor;
  SigUtils internal sigUtils;
  SigUtils internal sigUtilsUSDtb;

  uint256 internal proxyAdminOwnerPrivateKey;
  uint256 internal USDtbDeployerPrivateKey;
  uint256 internal USDtbProxyStandardOwnerPrivateKey;
  uint256 internal ownerPrivateKey;
  uint256 internal newOwnerPrivateKey;
  uint256 internal minterPrivateKey;
  uint256 internal redeemerPrivateKey;
  uint256 internal maker1PrivateKey;
  uint256 internal maker2PrivateKey;
  uint256 internal benefactorPrivateKey;
  uint256 internal beneficiaryPrivateKey;
  uint256 internal trader1PrivateKey;
  uint256 internal trader2PrivateKey;
  uint256 internal gatekeeperPrivateKey;
  uint256 internal bobPrivateKey;
  uint256 internal custodian1PrivateKey;
  uint256 internal custodian2PrivateKey;
  uint256 internal randomerPrivateKey;
  uint256 internal collateralManagerPrivateKey;
  uint256 internal smartContractSigner1PrivateKey;
  uint256 internal smartContractSigner2PrivateKey;
  uint256 internal smartContractSigner3PrivateKey;

  address internal proxyAdminOwner;
  address internal USDtbProxyStandardOwner;
  address internal USDtbDeployerAddresses;
  address internal owner;
  address internal newOwner;
  address internal minter;
  address internal redeemer;
  address internal collateralManager;
  address internal benefactor;
  address internal beneficiary;
  address internal maker1;
  address internal maker2;
  address internal trader1;
  address internal trader2;
  address internal gatekeeper;
  address internal bob;
  address internal custodian1;
  address internal custodian2;
  address internal randomer;
  address internal mockMultiSigWallet;
  address internal smartContractSigner1;
  address internal smartContractSigner2;
  address internal smartContractSigner3;

  address[] assets;
  address[] custodians;
  IUSDtbMinting.TokenConfig[] tokenConfig;
  IUSDtbMinting.GlobalConfig globalConfig;

  IUSDtbMinting.TokenConfig stableConfig;
  IUSDtbMinting.TokenConfig assetConfig;

  address internal NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Roles references
  bytes32 internal minterRole = keccak256("MINTER_ROLE");
  bytes32 internal gatekeeperRole = keccak256("GATEKEEPER_ROLE");
  bytes32 internal adminRole = 0x00;
  bytes32 internal redeemerRole = keccak256("REDEEMER_ROLE");
  bytes32 internal collateralManagerRole = keccak256("COLLATERAL_MANAGER_ROLE");
  bytes32 internal smartContractSignerRole = keccak256("SMART_CONTRACT_SIGNER_ROLE");

  // error encodings
  bytes internal InvalidAddress = abi.encodeWithSelector(IUSDtbMinting.InvalidAddress.selector);
  bytes internal InvalidAssetAddress = abi.encodeWithSelector(IUSDtbMinting.InvalidAssetAddress.selector);
  bytes internal InvalidOrder = abi.encodeWithSelector(IUSDtbMinting.InvalidOrder.selector);
  bytes internal InvalidAmount = abi.encodeWithSelector(IUSDtbMinting.InvalidAmount.selector);
  bytes internal InvalidRoute = abi.encodeWithSelector(IUSDtbMinting.InvalidRoute.selector);
  bytes internal InvalidStablePrice = abi.encodeWithSelector(IUSDtbMinting.InvalidStablePrice.selector);
  bytes internal InvalidAdminChange = abi.encodeWithSelector(ISingleAdminAccessControl.InvalidAdminChange.selector);
  bytes internal UnsupportedAsset = abi.encodeWithSelector(IUSDtbMinting.UnsupportedAsset.selector);
  bytes internal BenefactorNotWhitelisted = abi.encodeWithSelector(IUSDtbMinting.BenefactorNotWhitelisted.selector);
  bytes internal BeneficiaryNotApproved = abi.encodeWithSelector(IUSDtbMinting.BeneficiaryNotApproved.selector);
  bytes internal InvalidEIP712Signature = abi.encodeWithSelector(IUSDtbMinting.InvalidEIP712Signature.selector);
  bytes internal InvalidEIP1271Signature = abi.encodeWithSelector(IUSDtbMinting.InvalidEIP1271Signature.selector);
  bytes internal InvalidNonce = abi.encodeWithSelector(IUSDtbMinting.InvalidNonce.selector);
  bytes internal SignatureExpired = abi.encodeWithSelector(IUSDtbMinting.SignatureExpired.selector);
  bytes internal MaxMintPerBlockExceeded = abi.encodeWithSelector(IUSDtbMinting.MaxMintPerBlockExceeded.selector);
  bytes internal MaxRedeemPerBlockExceeded = abi.encodeWithSelector(IUSDtbMinting.MaxRedeemPerBlockExceeded.selector);
  bytes internal GlobalMaxMintPerBlockExceeded =
    abi.encodeWithSelector(IUSDtbMinting.GlobalMaxMintPerBlockExceeded.selector);
  bytes internal GlobalMaxRedeemPerBlockExceeded =
    abi.encodeWithSelector(IUSDtbMinting.GlobalMaxRedeemPerBlockExceeded.selector);

  // USDtb error encodings
  bytes internal ZeroAddressExceptionErr = abi.encodeWithSelector(IUSDtbDefinitions.ZeroAddressException.selector);
  bytes internal CantRenounceOwnershipErr = abi.encodeWithSelector(IUSDtbDefinitions.CantRenounceOwnership.selector);

  bytes32 internal constant ROUTE_TYPE = keccak256("Route(address[] addresses,uint128[] ratios)");
  bytes32 internal constant ORDER_TYPE = keccak256(
    "Order(uint128 expiry,uint128 nonce,address benefactor,address beneficiary,address asset,uint128 collateral_amount,uint128 usdtb_amount)"
  );

  uint128 internal _slippageRange = 50000000000000000;
  uint128 internal _stETHToDeposit = 50 * 10 ** 18;
  uint128 internal _stETHToWithdraw = 30 * 10 ** 18;
  uint128 internal _usdtbToMint = 8.75 * 10 ** 23;
  uint128 internal _maxMintPerBlock = 10e23;
  uint128 internal _maxRedeemPerBlock = _maxMintPerBlock;

  uint128 MAX_USDE_MINT_AND_REDEEM_PER_BLOCK = 2000000 * 10 ** 18; // 1 million USDtb
  uint128 ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK = 1000000 * 10 ** 18;
  uint128 STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK = 1000000 * 10 ** 18;

  string constant ORDER_ID_PREFIX = "RFQ-";
  bytes constant ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

  // Declared at contract level to avoid stack too deep
  SigUtils.Permit public permit;
  IUSDtbMinting.Order public mint;

  /// @notice packs r, s, v into signature bytes
  function _packRsv(bytes32 r, bytes32 s, uint8 v) internal pure returns (bytes memory) {
    bytes memory sig = new bytes(65);
    assembly {
      mstore(add(sig, 32), r)
      mstore(add(sig, 64), s)
      mstore8(add(sig, 96), v)
    }
    return sig;
  }

  function setUp() public virtual {
    utils = new Utils();

    stETHToken = new MockToken("Staked ETH", "sETH", 18, msg.sender);
    cbETHToken = new MockToken("Coinbase ETH", "cbETH", 18, msg.sender);
    rETHToken = new MockToken("Rocket Pool ETH", "rETH", 18, msg.sender);
    USDCToken = new MockToken("United States Dollar Coin", "USDC", 6, msg.sender);
    USDTToken = new MockToken("United States Dollar Token", "USDT", 6, msg.sender);

    sigUtils = new SigUtils(stETHToken.DOMAIN_SEPARATOR());

    assets = new address[](6);
    assets[0] = address(USDCToken);
    assets[1] = address(USDTToken);
    assets[2] = address(stETHToken);
    assets[3] = address(cbETHToken);
    assets[4] = address(rETHToken);
    assets[5] = NATIVE_TOKEN;

    proxyAdminOwnerPrivateKey = 0xA21CE;
    USDtbProxyStandardOwnerPrivateKey = 0xA11CE;
    USDtbDeployerPrivateKey = 0xA14DE;
    ownerPrivateKey = 0xA11CE;
    newOwnerPrivateKey = 0xA14CE;
    minterPrivateKey = 0xB44DE;
    redeemerPrivateKey = 0xB45DE;
    maker1PrivateKey = 0xA13CE;
    maker2PrivateKey = 0xA14CE;
    benefactorPrivateKey = 0x1DC;
    beneficiaryPrivateKey = 0x1DAC;
    trader1PrivateKey = 0x1DE;
    trader2PrivateKey = 0x1DEA;
    gatekeeperPrivateKey = 0x1DEA1;
    bobPrivateKey = 0x1DEA2;
    custodian1PrivateKey = 0x1DCDE;
    custodian2PrivateKey = 0x1DCCE;
    randomerPrivateKey = 0x1DECC;
    collateralManagerPrivateKey = 0x1DDCD;
    smartContractSigner1PrivateKey = 0x1DE4A;
    smartContractSigner2PrivateKey = 0x1DE3C;
    smartContractSigner3PrivateKey = 0x1DE2D;

    proxyAdminOwner = vm.addr(proxyAdminOwnerPrivateKey);
    USDtbProxyStandardOwner = vm.addr(USDtbProxyStandardOwnerPrivateKey);
    USDtbDeployerAddresses = vm.addr(USDtbDeployerPrivateKey);
    owner = vm.addr(ownerPrivateKey);
    newOwner = vm.addr(newOwnerPrivateKey);
    minter = vm.addr(minterPrivateKey);
    redeemer = vm.addr(redeemerPrivateKey);
    maker1 = vm.addr(maker1PrivateKey);
    maker2 = vm.addr(maker2PrivateKey);
    benefactor = vm.addr(benefactorPrivateKey);
    beneficiary = vm.addr(beneficiaryPrivateKey);
    trader1 = vm.addr(trader1PrivateKey);
    trader2 = vm.addr(trader2PrivateKey);
    gatekeeper = vm.addr(gatekeeperPrivateKey);
    bob = vm.addr(bobPrivateKey);
    custodian1 = vm.addr(custodian1PrivateKey);
    custodian2 = vm.addr(custodian2PrivateKey);
    randomer = vm.addr(randomerPrivateKey);
    smartContractSigner1 = vm.addr(smartContractSigner1PrivateKey);
    smartContractSigner2 = vm.addr(smartContractSigner2PrivateKey);
    smartContractSigner3 = vm.addr(smartContractSigner3PrivateKey);
    collateralManager = vm.addr(collateralManagerPrivateKey);

    custodians = new address[](1);
    custodians[0] = custodian1;

    vm.label(proxyAdminOwner, "proxyAdminOwner");
    vm.label(minter, "minter");
    vm.label(redeemer, "redeemer");
    vm.label(owner, "owner");
    vm.label(maker1, "maker1");
    vm.label(maker2, "maker2");
    vm.label(benefactor, "benefactor");
    vm.label(beneficiary, "beneficiary");
    vm.label(trader1, "trader1");
    vm.label(trader2, "trader2");
    vm.label(gatekeeper, "gatekeeper");
    vm.label(bob, "bob");
    vm.label(custodian1, "custodian1");
    vm.label(custodian2, "custodian2");
    vm.label(randomer, "randomer");
    vm.label(mockMultiSigWallet, "mockMultiSigWallet");
    vm.label(smartContractSigner1, "smartContractSigner1");
    vm.label(smartContractSigner2, "smartContractSigner2");

    for (uint256 i = 0; i <= 1; i++) {
      tokenConfig.push(
        IUSDtbMinting.TokenConfig({
          tokenType: IUSDtbMinting.TokenType.STABLE,
          maxMintPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          maxRedeemPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          isActive: true
        })
      );
    }

    for (uint256 j = 2; j <= 5; j++) {
      tokenConfig.push(
        IUSDtbMinting.TokenConfig({
          tokenType: IUSDtbMinting.TokenType.ASSET,
          maxMintPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          maxRedeemPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          isActive: true
        })
      );
    }

    stableConfig = IUSDtbMinting.TokenConfig({
      tokenType: IUSDtbMinting.TokenType.STABLE,
      maxMintPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      maxRedeemPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      isActive: true
    });
    assetConfig = IUSDtbMinting.TokenConfig({
      tokenType: IUSDtbMinting.TokenType.ASSET,
      maxMintPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      maxRedeemPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      isActive: true
    });

    globalConfig = IUSDtbMinting.GlobalConfig(MAX_USDE_MINT_AND_REDEEM_PER_BLOCK, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK);

    // Set the roles
    vm.startPrank(owner);
    USDtbMintingContract = new USDtbMinting(assets, tokenConfig, globalConfig, custodians, owner);

    USDtbMintingContract.setStablesDeltaLimit(100);

    USDtbMintingContract.grantRole(gatekeeperRole, gatekeeper);
    USDtbMintingContract.grantRole(redeemerRole, redeemer);
    USDtbMintingContract.grantRole(collateralManagerRole, collateralManager);
    USDtbMintingContract.grantRole(minterRole, minter);

    // Multi Sig - Smart Contract Based Signing
    MultiSigWalletBenefactor = new MockMultiSigWallet(owner, smartContractSigner1, smartContractSigner2);
    mockMultiSigWallet = address(MultiSigWalletBenefactor);

    USDtbMintingContract.addWhitelistedBenefactor(benefactor);
    USDtbMintingContract.addWhitelistedBenefactor(beneficiary);
    USDtbMintingContract.addWhitelistedBenefactor(trader1);
    USDtbMintingContract.addWhitelistedBenefactor(trader2);
    USDtbMintingContract.addWhitelistedBenefactor(redeemer);
    USDtbMintingContract.addWhitelistedBenefactor(mockMultiSigWallet);

    // Add self as approved custodian
    USDtbMintingContract.addCustodianAddress(address(USDtbMintingContract));

    // Mock Multi Sig assigned a quorum of three signers forming a composite benefactor
    MultiSigWalletBenefactor.grantRole(smartContractSignerRole, smartContractSigner1);
    MultiSigWalletBenefactor.grantRole(smartContractSignerRole, smartContractSigner2);

    // Mint stEth to the benefactor in order to test
    stETHToken.mint(_stETHToDeposit, benefactor);
    stETHToken.mint(_stETHToDeposit, mockMultiSigWallet);
    vm.stopPrank();

    vm.startPrank(beneficiary);
    USDtbMintingContract.setApprovedBeneficiary(beneficiary, true);
    USDtbMintingContract.setApprovedBeneficiary(benefactor, true);
    vm.stopPrank();

    vm.startPrank(benefactor);
    USDtbMintingContract.setApprovedBeneficiary(beneficiary, true);
    USDtbMintingContract.setApprovedBeneficiary(benefactor, true);
    USDtbMintingContract.setApprovedBeneficiary(trader1, true);
    USDtbMintingContract.setApprovedBeneficiary(trader2, true);
    USDtbMintingContract.setApprovedBeneficiary(address(MultiSigWalletBenefactor), true);
    vm.stopPrank();

    vm.startPrank(redeemer);
    USDtbMintingContract.setApprovedBeneficiary(redeemer, true);
    USDtbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.startPrank(address(MultiSigWalletBenefactor));
    USDtbMintingContract.setApprovedBeneficiary(mockMultiSigWallet, true);
    USDtbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    // deploy USDtb

    address deployerAddress = vm.addr(USDtbDeployerPrivateKey);

    vm.startBroadcast(USDtbDeployerPrivateKey);

    proxyAdminContract = new ProxyAdmin();

    // Covers the case where we deploy the contract with an address that is not the desired proxy admin owner
    if (deployerAddress != proxyAdminOwner) {
      proxyAdminContract.transferOwnership(proxyAdminOwner);
    }

    USDtbDeploymentAddressesInstance.proxyAdminAddress = address(proxyAdminContract);

    USDtbDeploymentAddressesInstance.proxyAddress = Upgrades.deployTransparentProxy(
      "USDtb.sol",
      address(USDtbDeploymentAddressesInstance.proxyAdminAddress),
      abi.encodeCall(USDtb.initialize, (newOwner, address(USDtbMintingContract)))
    );

    USDtbContractAsProxy = ITransparentUpgradeableProxy(payable(USDtbDeploymentAddressesInstance.proxyAddress));

    USDtbDeploymentAddressesInstance.USDtbImplementation =
      Upgrades.getImplementationAddress(USDtbDeploymentAddressesInstance.proxyAddress);

    USDtbDeploymentAddressesInstance.admin = Upgrades.getAdminAddress(USDtbDeploymentAddressesInstance.proxyAddress);

    usdtbToken = USDtb(USDtbDeploymentAddressesInstance.proxyAddress);
    vm.stopBroadcast();

    // Set USDtb token as USDtb Minting Token
    vm.prank(owner);
    USDtbMintingContract.setUSDtbToken(IUSDtb(address(usdtbToken)));
  }

  function generateRandomOrderId() internal view returns (string memory) {
    bytes memory randomChars = new bytes(13);
    for (uint256 i = 0; i < 13; i++) {
      uint256 randomIndex =
        uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) % ALPHANUMERIC.length;
      randomChars[i] = ALPHANUMERIC[randomIndex];
    }
    return string(abi.encodePacked(ORDER_ID_PREFIX, randomChars));
  }

  function _generateRouteTypeHash(IUSDtbMinting.Route memory route) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(ROUTE_TYPE, keccak256(abi.encodePacked(route.addresses)), keccak256(abi.encodePacked(route.ratios)))
    );
  }

  function signOrder(uint256 key, bytes32 digest, IUSDtbMinting.SignatureType sigType)
    public
    pure
    returns (IUSDtbMinting.Signature memory)
  {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
    bytes memory sigBytes = _packRsv(r, s, v);

    IUSDtbMinting.Signature memory signature =
      IUSDtbMinting.Signature({signature_type: sigType, signature_bytes: sigBytes});

    return signature;
  }

  // Generic mint setup reused in the tests to reduce lines of code
  function mint_setup(
    uint128 usdtbAmount,
    uint128 collateralAmount,
    IERC20 collateralToken,
    uint128 nonce,
    bool multipleMints
  )
    public
    returns (
      IUSDtbMinting.Order memory order,
      IUSDtbMinting.Signature memory takerSignature,
      IUSDtbMinting.Route memory route
    )
  {
    order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(uint128(block.timestamp + 10 minutes)),
      nonce: nonce,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(collateralToken),
      usdtb_amount: usdtbAmount,
      collateral_amount: collateralAmount
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    takerSignature = signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    collateralToken.approve(address(USDtbMintingContract), collateralAmount);
    vm.stopPrank();

    if (!multipleMints) {
      assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in USDtb balance");
      assertEq(collateralToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in collateral balance");
      assertEq(collateralToken.balanceOf(benefactor), collateralAmount, "Mismatch in collateral balance");
    }
  }

  // Generic redeem setup reused in the tests to reduce lines of code
  function redeem_setup(
    uint128 usdtbAmount,
    uint128 collateralAmount,
    IERC20 collateralAsset,
    uint128 nonce,
    bool multipleRedeem
  ) public returns (IUSDtbMinting.Order memory redeemOrder, IUSDtbMinting.Signature memory takerSignature2) {
    (IUSDtbMinting.Order memory mintOrder, IUSDtbMinting.Signature memory takerSignature, IUSDtbMinting.Route memory route)
    = mint_setup(usdtbAmount, collateralAmount, collateralAsset, nonce, true);

    vm.prank(minter);
    USDtbMintingContract.mint(mintOrder, route, takerSignature);

    //redeem
    redeemOrder = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(uint128(block.timestamp + 10 minutes)),
      nonce: nonce + 1,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: address(collateralAsset),
      usdtb_amount: usdtbAmount,
      collateral_amount: collateralAmount
    });

    // taker
    vm.startPrank(beneficiary);
    usdtbToken.approve(address(USDtbMintingContract), usdtbAmount);

    bytes32 digest3 = USDtbMintingContract.hashOrder(redeemOrder);
    takerSignature2 = signOrder(beneficiaryPrivateKey, digest3, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(owner);
    USDtbMintingContract.grantRole(redeemerRole, redeemer);
    vm.stopPrank();

    if (!multipleRedeem) {
      assertEq(
        collateralAsset.balanceOf(address(USDtbMintingContract)), collateralAmount, "Mismatch in collateral balance"
      );
      assertEq(collateralAsset.balanceOf(beneficiary), 0, "Mismatch in collateral balance");
      assertEq(usdtbToken.balanceOf(beneficiary), usdtbAmount, "Mismatch in USDtb balance");
    }
  }
}
