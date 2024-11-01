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
import "../../contracts/ustb/UStb.sol";
import "../../contracts/ustb/IUStbMinting.sol";
import "../../contracts/ustb/IUStbMintingEvents.sol";
import "../../contracts/ustb/UStbMinting.sol";
import "../../contracts/interfaces/ISingleAdminAccessControl.sol";
import "../../contracts/ustb/IUStbDefinitions.sol";
import "../../contracts/mock/MockMultisigWallet.sol";
import "../../contracts/ustb/IUStbDefinitions.sol";

contract UStbMintingBaseSetup is Test, IUStbMintingEvents, IUStbDefinitions {
  Utils internal utils;

  struct UStbDeploymentAddresses {
    address proxyAddress;
    address UStbImplementation;
    address admin;
    address proxyAdminAddress;
  }

  UStb internal ustbToken;
  UStbDeploymentAddresses internal UStbDeploymentAddressesInstance;
  ITransparentUpgradeableProxy internal UStbContractAsProxy;
  ProxyAdmin proxyAdminContract;

  MockToken internal stETHToken;
  MockToken internal cbETHToken;
  MockToken internal rETHToken;
  MockToken internal USDCToken;
  MockToken internal USDTToken;
  MockToken internal token;
  UStbMinting internal UStbMintingContract;
  MockMultiSigWallet internal MultiSigWalletBenefactor;
  SigUtils internal sigUtils;
  SigUtils internal sigUtilsUStb;

  uint256 internal proxyAdminOwnerPrivateKey;
  uint256 internal UStbDeployerPrivateKey;
  uint256 internal UStbProxyStandardOwnerPrivateKey;
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
  address internal UStbProxyStandardOwner;
  address internal UStbDeployerAddresses;
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
  IUStbMinting.TokenConfig[] tokenConfig;
  IUStbMinting.GlobalConfig globalConfig;

  IUStbMinting.TokenConfig stableConfig;
  IUStbMinting.TokenConfig assetConfig;

  address internal NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Roles references
  bytes32 internal minterRole = keccak256("MINTER_ROLE");
  bytes32 internal gatekeeperRole = keccak256("GATEKEEPER_ROLE");
  bytes32 internal adminRole = 0x00;
  bytes32 internal redeemerRole = keccak256("REDEEMER_ROLE");
  bytes32 internal collateralManagerRole = keccak256("COLLATERAL_MANAGER_ROLE");
  bytes32 internal smartContractSignerRole = keccak256("SMART_CONTRACT_SIGNER_ROLE");

  // error encodings
  bytes internal InvalidAddress = abi.encodeWithSelector(IUStbMinting.InvalidAddress.selector);
  bytes internal InvalidAssetAddress = abi.encodeWithSelector(IUStbMinting.InvalidAssetAddress.selector);
  bytes internal InvalidOrder = abi.encodeWithSelector(IUStbMinting.InvalidOrder.selector);
  bytes internal InvalidAmount = abi.encodeWithSelector(IUStbMinting.InvalidAmount.selector);
  bytes internal InvalidRoute = abi.encodeWithSelector(IUStbMinting.InvalidRoute.selector);
  bytes internal InvalidStablePrice = abi.encodeWithSelector(IUStbMinting.InvalidStablePrice.selector);
  bytes internal InvalidAdminChange = abi.encodeWithSelector(ISingleAdminAccessControl.InvalidAdminChange.selector);
  bytes internal UnsupportedAsset = abi.encodeWithSelector(IUStbMinting.UnsupportedAsset.selector);
  bytes internal BenefactorNotWhitelisted = abi.encodeWithSelector(IUStbMinting.BenefactorNotWhitelisted.selector);
  bytes internal BeneficiaryNotApproved = abi.encodeWithSelector(IUStbMinting.BeneficiaryNotApproved.selector);
  bytes internal InvalidEIP712Signature = abi.encodeWithSelector(IUStbMinting.InvalidEIP712Signature.selector);
  bytes internal InvalidEIP1271Signature = abi.encodeWithSelector(IUStbMinting.InvalidEIP1271Signature.selector);
  bytes internal InvalidNonce = abi.encodeWithSelector(IUStbMinting.InvalidNonce.selector);
  bytes internal SignatureExpired = abi.encodeWithSelector(IUStbMinting.SignatureExpired.selector);
  bytes internal MaxMintPerBlockExceeded = abi.encodeWithSelector(IUStbMinting.MaxMintPerBlockExceeded.selector);
  bytes internal MaxRedeemPerBlockExceeded = abi.encodeWithSelector(IUStbMinting.MaxRedeemPerBlockExceeded.selector);
  bytes internal GlobalMaxMintPerBlockExceeded =
    abi.encodeWithSelector(IUStbMinting.GlobalMaxMintPerBlockExceeded.selector);
  bytes internal GlobalMaxRedeemPerBlockExceeded =
    abi.encodeWithSelector(IUStbMinting.GlobalMaxRedeemPerBlockExceeded.selector);

  // UStb error encodings
  bytes internal ZeroAddressExceptionErr = abi.encodeWithSelector(IUStbDefinitions.ZeroAddressException.selector);
  bytes internal CantRenounceOwnershipErr = abi.encodeWithSelector(IUStbDefinitions.CantRenounceOwnership.selector);

  bytes32 internal constant ROUTE_TYPE = keccak256("Route(address[] addresses,uint128[] ratios)");
  bytes32 internal constant ORDER_TYPE = keccak256(
    "Order(uint128 expiry,uint128 nonce,address benefactor,address beneficiary,address asset,uint128 collateral_amount,uint128 ustb_amount)"
  );

  uint128 internal _slippageRange = 50000000000000000;
  uint128 internal _stETHToDeposit = 50 * 10 ** 18;
  uint128 internal _stETHToWithdraw = 30 * 10 ** 18;
  uint128 internal _ustbToMint = 8.75 * 10 ** 23;
  uint128 internal _maxMintPerBlock = 10e23;
  uint128 internal _maxRedeemPerBlock = _maxMintPerBlock;

  uint128 MAX_USDE_MINT_AND_REDEEM_PER_BLOCK = 2000000 * 10 ** 18; // 1 million UStb
  uint128 ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK = 1000000 * 10 ** 18;
  uint128 STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK = 1000000 * 10 ** 18;

  string constant ORDER_ID_PREFIX = "RFQ-";
  bytes constant ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

  // Declared at contract level to avoid stack too deep
  SigUtils.Permit public permit;
  IUStbMinting.Order public mint;

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
    UStbProxyStandardOwnerPrivateKey = 0xA11CE;
    UStbDeployerPrivateKey = 0xA14DE;
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
    UStbProxyStandardOwner = vm.addr(UStbProxyStandardOwnerPrivateKey);
    UStbDeployerAddresses = vm.addr(UStbDeployerPrivateKey);
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
        IUStbMinting.TokenConfig({
          tokenType: IUStbMinting.TokenType.STABLE,
          maxMintPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          maxRedeemPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          isActive: true
        })
      );
    }

    for (uint256 j = 2; j <= 5; j++) {
      tokenConfig.push(
        IUStbMinting.TokenConfig({
          tokenType: IUStbMinting.TokenType.ASSET,
          maxMintPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          maxRedeemPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
          isActive: true
        })
      );
    }

    stableConfig = IUStbMinting.TokenConfig({
      tokenType: IUStbMinting.TokenType.STABLE,
      maxMintPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      maxRedeemPerBlock: STABLE_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      isActive: true
    });
    assetConfig = IUStbMinting.TokenConfig({
      tokenType: IUStbMinting.TokenType.ASSET,
      maxMintPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      maxRedeemPerBlock: ASSET_MAX_USTB_MINT_AND_REDEEM_PER_BLOCK,
      isActive: true
    });

    globalConfig = IUStbMinting.GlobalConfig(MAX_USDE_MINT_AND_REDEEM_PER_BLOCK, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK);

    // Set the roles
    vm.startPrank(owner);
    UStbMintingContract = new UStbMinting(assets, tokenConfig, globalConfig, custodians, owner);

    UStbMintingContract.setStablesDeltaLimit(100);

    UStbMintingContract.grantRole(gatekeeperRole, gatekeeper);
    UStbMintingContract.grantRole(redeemerRole, redeemer);
    UStbMintingContract.grantRole(collateralManagerRole, collateralManager);
    UStbMintingContract.grantRole(minterRole, minter);

    // Multi Sig - Smart Contract Based Signing
    MultiSigWalletBenefactor = new MockMultiSigWallet(owner, smartContractSigner1, smartContractSigner2);
    mockMultiSigWallet = address(MultiSigWalletBenefactor);

    UStbMintingContract.addWhitelistedBenefactor(benefactor);
    UStbMintingContract.addWhitelistedBenefactor(beneficiary);
    UStbMintingContract.addWhitelistedBenefactor(trader1);
    UStbMintingContract.addWhitelistedBenefactor(trader2);
    UStbMintingContract.addWhitelistedBenefactor(redeemer);
    UStbMintingContract.addWhitelistedBenefactor(mockMultiSigWallet);

    // Add self as approved custodian
    UStbMintingContract.addCustodianAddress(address(UStbMintingContract));

    // Mock Multi Sig assigned a quorum of three signers forming a composite benefactor
    MultiSigWalletBenefactor.grantRole(smartContractSignerRole, smartContractSigner1);
    MultiSigWalletBenefactor.grantRole(smartContractSignerRole, smartContractSigner2);

    // Mint stEth to the benefactor in order to test
    stETHToken.mint(_stETHToDeposit, benefactor);
    stETHToken.mint(_stETHToDeposit, mockMultiSigWallet);
    vm.stopPrank();

    vm.startPrank(beneficiary);
    UStbMintingContract.setApprovedBeneficiary(beneficiary, true);
    UStbMintingContract.setApprovedBeneficiary(benefactor, true);
    vm.stopPrank();

    vm.startPrank(benefactor);
    UStbMintingContract.setApprovedBeneficiary(beneficiary, true);
    UStbMintingContract.setApprovedBeneficiary(benefactor, true);
    UStbMintingContract.setApprovedBeneficiary(trader1, true);
    UStbMintingContract.setApprovedBeneficiary(trader2, true);
    UStbMintingContract.setApprovedBeneficiary(address(MultiSigWalletBenefactor), true);
    vm.stopPrank();

    vm.startPrank(redeemer);
    UStbMintingContract.setApprovedBeneficiary(redeemer, true);
    UStbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.startPrank(address(MultiSigWalletBenefactor));
    UStbMintingContract.setApprovedBeneficiary(mockMultiSigWallet, true);
    UStbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    // deploy UStb

    address deployerAddress = vm.addr(UStbDeployerPrivateKey);

    vm.startBroadcast(UStbDeployerPrivateKey);

    proxyAdminContract = new ProxyAdmin();

    // Covers the case where we deploy the contract with an address that is not the desired proxy admin owner
    if (deployerAddress != proxyAdminOwner) {
      proxyAdminContract.transferOwnership(proxyAdminOwner);
    }

    UStbDeploymentAddressesInstance.proxyAdminAddress = address(proxyAdminContract);

    UStbDeploymentAddressesInstance.proxyAddress = Upgrades.deployTransparentProxy(
      "UStb.sol",
      address(UStbDeploymentAddressesInstance.proxyAdminAddress),
      abi.encodeCall(UStb.initialize, (newOwner, address(UStbMintingContract)))
    );

    UStbContractAsProxy = ITransparentUpgradeableProxy(payable(UStbDeploymentAddressesInstance.proxyAddress));

    UStbDeploymentAddressesInstance.UStbImplementation =
      Upgrades.getImplementationAddress(UStbDeploymentAddressesInstance.proxyAddress);

    UStbDeploymentAddressesInstance.admin = Upgrades.getAdminAddress(UStbDeploymentAddressesInstance.proxyAddress);

    ustbToken = UStb(UStbDeploymentAddressesInstance.proxyAddress);
    vm.stopBroadcast();

    // Set UStb token as UStb Minting Token
    vm.prank(owner);
    UStbMintingContract.setUStbToken(IUStb(address(ustbToken)));
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

  function _generateRouteTypeHash(IUStbMinting.Route memory route) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(ROUTE_TYPE, keccak256(abi.encodePacked(route.addresses)), keccak256(abi.encodePacked(route.ratios)))
    );
  }

  function signOrder(uint256 key, bytes32 digest, IUStbMinting.SignatureType sigType)
    public
    pure
    returns (IUStbMinting.Signature memory)
  {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
    bytes memory sigBytes = _packRsv(r, s, v);

    IUStbMinting.Signature memory signature =
      IUStbMinting.Signature({signature_type: sigType, signature_bytes: sigBytes});

    return signature;
  }

  // Generic mint setup reused in the tests to reduce lines of code
  function mint_setup(
    uint128 ustbAmount,
    uint128 collateralAmount,
    IERC20 collateralToken,
    uint128 nonce,
    bool multipleMints
  )
    public
    returns (
      IUStbMinting.Order memory order,
      IUStbMinting.Signature memory takerSignature,
      IUStbMinting.Route memory route
    )
  {
    order = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(uint128(block.timestamp + 10 minutes)),
      nonce: nonce,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(collateralToken),
      ustb_amount: ustbAmount,
      collateral_amount: collateralAmount
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UStbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    route = IUStbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    takerSignature = signOrder(benefactorPrivateKey, digest1, IUStbMinting.SignatureType.EIP712);
    collateralToken.approve(address(UStbMintingContract), collateralAmount);
    vm.stopPrank();

    if (!multipleMints) {
      assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in UStb balance");
      assertEq(collateralToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in collateral balance");
      assertEq(collateralToken.balanceOf(benefactor), collateralAmount, "Mismatch in collateral balance");
    }
  }

  // Generic redeem setup reused in the tests to reduce lines of code
  function redeem_setup(
    uint128 ustbAmount,
    uint128 collateralAmount,
    IERC20 collateralAsset,
    uint128 nonce,
    bool multipleRedeem
  ) public returns (IUStbMinting.Order memory redeemOrder, IUStbMinting.Signature memory takerSignature2) {
    (IUStbMinting.Order memory mintOrder, IUStbMinting.Signature memory takerSignature, IUStbMinting.Route memory route)
    = mint_setup(ustbAmount, collateralAmount, collateralAsset, nonce, true);

    vm.prank(minter);
    UStbMintingContract.mint(mintOrder, route, takerSignature);

    //redeem
    redeemOrder = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(uint128(block.timestamp + 10 minutes)),
      nonce: nonce + 1,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: address(collateralAsset),
      ustb_amount: ustbAmount,
      collateral_amount: collateralAmount
    });

    // taker
    vm.startPrank(beneficiary);
    ustbToken.approve(address(UStbMintingContract), ustbAmount);

    bytes32 digest3 = UStbMintingContract.hashOrder(redeemOrder);
    takerSignature2 = signOrder(beneficiaryPrivateKey, digest3, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(owner);
    UStbMintingContract.grantRole(redeemerRole, redeemer);
    vm.stopPrank();

    if (!multipleRedeem) {
      assertEq(
        collateralAsset.balanceOf(address(UStbMintingContract)), collateralAmount, "Mismatch in collateral balance"
      );
      assertEq(collateralAsset.balanceOf(beneficiary), 0, "Mismatch in collateral balance");
      assertEq(ustbToken.balanceOf(beneficiary), ustbAmount, "Mismatch in UStb balance");
    }
  }
}
