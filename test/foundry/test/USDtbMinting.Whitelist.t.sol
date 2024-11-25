// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../USDtbMinting.utils.sol";

contract USDtbMintingWhitelistTest is USDtbMintingUtils {
  function setUp() public override {
    super.setUp();
    vm.deal(benefactor, _stETHToDeposit);
  }

  function generate_nonce() public view returns (uint128) {
    return uint128(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))));
  }

  function test_whitelist_mint() public {
    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: generate_nonce(),
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint / 2
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

    vm.prank(owner);
    USDtbMintingContract.removeWhitelistedBenefactor(benefactor);

    vm.expectRevert(BenefactorNotWhitelisted);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    vm.prank(owner);
    USDtbMintingContract.addWhitelistedBenefactor(benefactor);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    // assert balances
    assertEq(stETHToken.balanceOf(address(benefactor)), 0);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(address(beneficiary)), _usdtbToMint / 2);
  }

  function test_whitelist_redeem() public {
    (IUSDtbMinting.Order memory mintOrder, IUSDtbMinting.Signature memory sig, IUSDtbMinting.Route memory route) =
      mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    USDtbMintingContract.mint(mintOrder, route, sig);

    IUSDtbMinting.Order memory redeemOrder = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 47,
      benefactor: beneficiary,
      beneficiary: benefactor, // switched
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    // taker
    vm.startPrank(beneficiary);
    usdtbToken.approve(address(USDtbMintingContract), _usdtbToMint);

    bytes32 redeemDigest = USDtbMintingContract.hashOrder(redeemOrder);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(beneficiaryPrivateKey, redeemDigest, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(owner);
    vm.expectRevert(InvalidAddress);
    USDtbMintingContract.removeWhitelistedBenefactor(owner);

    USDtbMintingContract.removeWhitelistedBenefactor(beneficiary);
    vm.stopPrank();

    vm.expectRevert(BenefactorNotWhitelisted);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, takerSignature);

    vm.prank(owner);
    USDtbMintingContract.addWhitelistedBenefactor(beneficiary);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, takerSignature);

    assertEq(stETHToken.balanceOf(address(benefactor)), _stETHToDeposit);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), 0);
    assertEq(usdtbToken.balanceOf(address(beneficiary)), 0);
  }

  function test_non_whitelisted_beneficiary_mint() public {
    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: generate_nonce(),
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint / 2
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

    vm.expectRevert(BeneficiaryNotApproved);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    vm.prank(benefactor);
    USDtbMintingContract.setApprovedBeneficiary(owner, true);
    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    // assert balances
    assertEq(stETHToken.balanceOf(address(benefactor)), 0);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(address(owner)), _usdtbToMint / 2);
  }

  function test_non_whitelisted_beneficiary_redeem() public {
    vm.prank(benefactor);
    USDtbMintingContract.setApprovedBeneficiary(owner, true);
    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 3423423,
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      usdtb_amount: _usdtbToMint,
      collateral_amount: _stETHToDeposit
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    IERC20(address(stETHToken)).approve(address(USDtbMintingContract), _stETHToDeposit);
    vm.stopPrank();

    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    IUSDtbMinting.Order memory redeemOrder = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 44524527,
      benefactor: owner,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    // taker
    vm.startPrank(owner);
    usdtbToken.approve(address(USDtbMintingContract), _usdtbToMint);

    bytes32 redeemDigest = USDtbMintingContract.hashOrder(redeemOrder);
    IUSDtbMinting.Signature memory redeemTakerSignature =
      signOrder(ownerPrivateKey, redeemDigest, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BenefactorNotWhitelisted);
    USDtbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    USDtbMintingContract.addWhitelistedBenefactor(owner);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BeneficiaryNotApproved);
    USDtbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    USDtbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, redeemTakerSignature);
  }

  function test_whitelisted_beneficiary_whitelist_enabled_transfer_redeem() public {
    vm.prank(benefactor);
    USDtbMintingContract.setApprovedBeneficiary(owner, true);
    IUSDtbMinting.Order memory order = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 3423423,
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      usdtb_amount: _usdtbToMint,
      collateral_amount: _stETHToDeposit
    });

    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUSDtbMinting.Route memory route = IUSDtbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    IUSDtbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);
    IERC20(address(stETHToken)).approve(address(USDtbMintingContract), _stETHToDeposit);
    vm.stopPrank();

    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);

    // set the transfer state to WHITELIST_ENABLED
    vm.startPrank(newOwner);
    usdtbToken.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    usdtbToken.grantRole(keccak256("WHITELISTED_ROLE"), owner);
    vm.stopPrank();

    IUSDtbMinting.Order memory redeemOrder = IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 44524527,
      benefactor: owner,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdtb_amount: _usdtbToMint
    });

    // taker
    vm.startPrank(owner);
    usdtbToken.approve(address(USDtbMintingContract), _usdtbToMint);

    bytes32 redeemDigest = USDtbMintingContract.hashOrder(redeemOrder);
    IUSDtbMinting.Signature memory redeemTakerSignature =
      signOrder(ownerPrivateKey, redeemDigest, IUSDtbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BenefactorNotWhitelisted);
    USDtbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    USDtbMintingContract.addWhitelistedBenefactor(owner);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BeneficiaryNotApproved);
    USDtbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    USDtbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, redeemTakerSignature);
  }
}
