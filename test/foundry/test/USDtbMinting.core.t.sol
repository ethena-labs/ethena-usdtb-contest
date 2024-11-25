// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../USDtbMinting.utils.sol";

contract USDtbMintingCoreTest is USDtbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_mint() public {
    executeMint(stETHToken);
  }

  function test_redeem() public {
    executeRedeem(stETHToken);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in stETH balance");
    assertEq(stETHToken.balanceOf(beneficiary), _stETHToDeposit, "Mismatch in stETH balance");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in USDtb balance");
  }

  function test_redeem_invalidNonce_revert() public {
    // Unset the max redeem per block limit
    vm.startPrank(owner);
    USDtbMintingContract.setMaxRedeemPerBlock(MAX_USDE_MINT_AND_REDEEM_PER_BLOCK * 10, address(stETHToken));
    USDtbMintingContract.setGlobalMaxRedeemPerBlock(type(uint128).max);
    vm.stopPrank();

    (IUSDtbMinting.Order memory redeemOrder, IUSDtbMinting.Signature memory takerSignature2) =
      redeem_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.startPrank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, takerSignature2);

    vm.expectRevert(InvalidNonce);
    USDtbMintingContract.redeem(redeemOrder, takerSignature2);
  }

  function test_nativeEth_withdraw() public {
    vm.deal(address(USDtbMintingContract), _stETHToDeposit);

    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 8,
      benefactor: benefactor,
      beneficiary: benefactor,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(USDtbMintingContract), _stETHToDeposit);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(usdtbToken.balanceOf(benefactor), 0);

    vm.recordLogs();
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();

    assertEq(usdtbToken.balanceOf(benefactor), _usdtbToMint);

    //redeem
    IUSDtbMinting.Order memory redeemOrder = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 800,
      benefactor: benefactor,
      beneficiary: benefactor,
      collateral_asset: NATIVE_TOKEN,
      usdtb_amount: _usdtbToMint,
      collateral_amount: _stETHToDeposit
    });

    // taker
    vm.startPrank(benefactor);
    usdtbToken.approve(address(USDtbMintingContract), _usdtbToMint);

    bytes32 digest3 = USDtbMintingContract.hashOrder(redeemOrder);
    IUSDtbMinting.Signature memory takerSignature2 =
      signOrder(benefactorPrivateKey, digest3, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, takerSignature2);

    assertEq(stETHToken.balanceOf(benefactor), 0);
    assertEq(usdtbToken.balanceOf(benefactor), 0);
    assertEq(benefactor.balance, _stETHToDeposit);

    vm.stopPrank();
  }

  function test_fuzz_mint_noSlippage(uint128 expectedAmount) public {
    vm.assume(expectedAmount > 0 && expectedAmount < _maxMintPerBlock);

    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature, IUSDtbMinting.Route memory route)
    = mint_setup(expectedAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.recordLogs();
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
    assertEq(stETHToken.balanceOf(benefactor), 0);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(beneficiary), expectedAmount);
  }

  function test_multipleValid_custodyRatios_addresses() public {
    uint128 _smallUsdeToMint = 1.75 * 10 ** 23;
    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 14,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _smallUsdeToMint
    });

    address[] memory targets = new address[](3);
    targets[0] = address(USDtbMintingContract);
    targets[1] = custodian1;
    targets[2] = custodian2;

    uint128[] memory ratios = new uint128[](3);
    ratios[0] = 3_000;
    ratios[1] = 4_000;
    ratios[2] = 3_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(USDtbMintingContract), _stETHToDeposit);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

    vm.prank(minter);
    vm.expectRevert(InvalidRoute);
    USDtbMintingContract.mint(order, route, takerSignature);

    vm.prank(owner);
    USDtbMintingContract.addCustodianAddress(custodian2);

    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), 0);
    assertEq(usdtbToken.balanceOf(beneficiary), _smallUsdeToMint);

    assertEq(stETHToken.balanceOf(address(custodian1)), (_stETHToDeposit * 4) / 10);
    assertEq(stETHToken.balanceOf(address(custodian2)), (_stETHToDeposit * 3) / 10);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), (_stETHToDeposit * 3) / 10);

    // remove custodian and expect reversion
    vm.prank(owner);
    USDtbMintingContract.removeCustodianAddress(custodian2);

    vm.prank(minter);
    vm.expectRevert(InvalidRoute);
    USDtbMintingContract.mint(order, route, takerSignature);
  }

  function test_fuzz_multipleInvalid_custodyRatios_revert(uint128 ratio1) public {
    ratio1 = uint128(bound(ratio1, 0, type(uint128).max - 7_000));
    vm.assume(ratio1 != 3_000);

    IUSDtbMinting.Order memory mintOrder = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 15,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    address[] memory targets = new address[](2);
    targets[0] = address(USDtbMintingContract);
    targets[1] = owner;

    uint128[] memory ratios = new uint128[](2);
    ratios[0] = ratio1;
    ratios[1] = 7_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    stETHToken.approve(address(USDtbMintingContract), _stETHToDeposit);

    bytes32 digest1 = USDtbMintingContract.hashOrder(mintOrder);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

    vm.expectRevert(InvalidRoute);
    vm.prank(minter);
    USDtbMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(beneficiary), 0);

    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), 0);
    assertEq(stETHToken.balanceOf(owner), 0);
  }

  function test_fuzz_singleInvalid_custodyRatio_revert(uint128 ratio1) public {
    vm.assume(ratio1 != 10_000);

    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 16,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = ratio1;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(USDtbMintingContract), _stETHToDeposit);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

    vm.expectRevert(InvalidRoute);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(beneficiary), 0);

    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), 0);
  }

  function test_unsupported_assets_ERC20_revert() public {
    vm.startPrank(owner);
    USDtbMintingContract.removeSupportedAsset(address(stETHToken));
    stETHToken.mint(_stETHToDeposit, benefactor);
    vm.stopPrank();

    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 18,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(USDtbMintingContract), _stETHToDeposit);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.recordLogs();
    vm.expectRevert(UnsupportedAsset);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
  }

  function test_unsupported_assets_ETH_revert() public {
    vm.startPrank(owner);
    vm.deal(benefactor, _stETHToDeposit);
    vm.stopPrank();

    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 19,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: NATIVE_TOKEN,
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(USDtbMintingContract), _stETHToDeposit);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.recordLogs();
    vm.expectRevert(UnsupportedAsset);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
  }

  function test_expired_orders_revert() public {
    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature, IUSDtbMinting.Route memory route)
    = mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.warp(block.timestamp + 11 minutes);

    vm.recordLogs();
    vm.expectRevert(SignatureExpired);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
  }

  function test_add_and_remove_supported_asset() public {
    address asset = address(20);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    vm.startPrank(owner);
    USDtbMintingContract.addSupportedAsset(asset, assetConfig);
    assertTrue(USDtbMintingContract.isSupportedAsset(asset));

    vm.expectEmit(true, false, false, false);
    emit AssetRemoved(asset);
    USDtbMintingContract.removeSupportedAsset(asset);
    assertFalse(USDtbMintingContract.isSupportedAsset(asset));
  }

  function test_cannot_add_asset_already_supported_revert() public {
    address asset = address(20);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    vm.startPrank(owner);
    USDtbMintingContract.addSupportedAsset(asset, assetConfig);
    assertTrue(USDtbMintingContract.isSupportedAsset(asset));

    vm.expectRevert(InvalidAssetAddress);
    USDtbMintingContract.addSupportedAsset(asset, assetConfig);
  }

  function test_cannot_removeAsset_not_supported_revert() public {
    address asset = address(20);
    assertFalse(USDtbMintingContract.isSupportedAsset(asset));

    vm.prank(owner);
    vm.expectRevert(InvalidAssetAddress);
    USDtbMintingContract.removeSupportedAsset(asset);
  }

  function test_cannotAdd_addressZero_revert() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAssetAddress);
    USDtbMintingContract.addSupportedAsset(address(0), assetConfig);
  }

  function test_cannotAdd_USDtb_revert() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAssetAddress);
    USDtbMintingContract.addSupportedAsset(address(usdtbToken), stableConfig);
  }

  function test_sending_redeem_order_to_mint_revert() public {
    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature) =
      redeem_setup(1 ether, 50 ether, stETHToken, 20, false);

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    vm.expectRevert(InvalidOrder);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
  }

  function test_sending_mint_order_to_redeem_revert() public {
    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature,) =
      mint_setup(1 ether, 50 ether, stETHToken, 20, false);

    vm.expectRevert(InvalidOrder);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(order, takerSignature);
  }

  function test_receive_eth() public {
    assertEq(address(USDtbMintingContract).balance, 0);
    vm.deal(owner, 10_000 ether);
    vm.prank(owner);
    (bool success,) = address(USDtbMintingContract).call{value: 10_000 ether}("");
    assertTrue(success);
    assertEq(address(USDtbMintingContract).balance, 10_000 ether);
  }
}
