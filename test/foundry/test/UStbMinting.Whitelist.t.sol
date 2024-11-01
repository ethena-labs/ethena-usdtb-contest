// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UStbMinting.utils.sol";

contract UStbMintingWhitelistTest is UStbMintingUtils {
  function setUp() public override {
    super.setUp();
    vm.deal(benefactor, _stETHToDeposit);
  }

  function generate_nonce() public view returns (uint128) {
    return uint128(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))));
  }

  function test_whitelist_mint() public {
    IUStbMinting.Order memory order = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: generate_nonce(),
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      ustb_amount: _ustbToMint / 2
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UStbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUStbMinting.Route memory route = IUStbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UStbMintingContract), _stETHToDeposit);

    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    IUStbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.prank(owner);
    UStbMintingContract.removeWhitelistedBenefactor(benefactor);

    vm.expectRevert(BenefactorNotWhitelisted);
    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    vm.prank(owner);
    UStbMintingContract.addWhitelistedBenefactor(benefactor);
    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    // assert balances
    assertEq(stETHToken.balanceOf(address(benefactor)), 0);
    assertEq(stETHToken.balanceOf(address(UStbMintingContract)), _stETHToDeposit);
    assertEq(ustbToken.balanceOf(address(beneficiary)), _ustbToMint / 2);
  }

  function test_whitelist_redeem() public {
    (IUStbMinting.Order memory mintOrder, IUStbMinting.Signature memory sig, IUStbMinting.Route memory route) =
      mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    UStbMintingContract.mint(mintOrder, route, sig);

    IUStbMinting.Order memory redeemOrder = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 47,
      benefactor: beneficiary,
      beneficiary: benefactor, // switched
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      ustb_amount: _ustbToMint
    });

    // taker
    vm.startPrank(beneficiary);
    ustbToken.approve(address(UStbMintingContract), _ustbToMint);

    bytes32 redeemDigest = UStbMintingContract.hashOrder(redeemOrder);
    IUStbMinting.Signature memory takerSignature =
      signOrder(beneficiaryPrivateKey, redeemDigest, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(owner);
    vm.expectRevert(InvalidAddress);
    UStbMintingContract.removeWhitelistedBenefactor(owner);

    UStbMintingContract.removeWhitelistedBenefactor(beneficiary);
    vm.stopPrank();

    vm.expectRevert(BenefactorNotWhitelisted);
    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder, takerSignature);

    vm.prank(owner);
    UStbMintingContract.addWhitelistedBenefactor(beneficiary);
    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder, takerSignature);

    assertEq(stETHToken.balanceOf(address(benefactor)), _stETHToDeposit);
    assertEq(stETHToken.balanceOf(address(UStbMintingContract)), 0);
    assertEq(ustbToken.balanceOf(address(beneficiary)), 0);
  }

  function test_non_whitelisted_beneficiary_mint() public {
    IUStbMinting.Order memory order = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: generate_nonce(),
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      ustb_amount: _ustbToMint / 2
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UStbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUStbMinting.Route memory route = IUStbMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UStbMintingContract), _stETHToDeposit);

    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    IUStbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.expectRevert(BeneficiaryNotApproved);
    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    vm.prank(benefactor);
    UStbMintingContract.setApprovedBeneficiary(owner, true);
    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    // assert balances
    assertEq(stETHToken.balanceOf(address(benefactor)), 0);
    assertEq(stETHToken.balanceOf(address(UStbMintingContract)), _stETHToDeposit);
    assertEq(ustbToken.balanceOf(address(owner)), _ustbToMint / 2);
  }

  function test_non_whitelisted_beneficiary_redeem() public {
    vm.prank(benefactor);
    UStbMintingContract.setApprovedBeneficiary(owner, true);
    IUStbMinting.Order memory order = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 3423423,
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      ustb_amount: _ustbToMint,
      collateral_amount: _stETHToDeposit
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UStbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUStbMinting.Route memory route = IUStbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    IUStbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUStbMinting.SignatureType.EIP712);
    IERC20(address(stETHToken)).approve(address(UStbMintingContract), _stETHToDeposit);
    vm.stopPrank();

    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    IUStbMinting.Order memory redeemOrder = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 44524527,
      benefactor: owner,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      ustb_amount: _ustbToMint
    });

    // taker
    vm.startPrank(owner);
    ustbToken.approve(address(UStbMintingContract), _ustbToMint);

    bytes32 redeemDigest = UStbMintingContract.hashOrder(redeemOrder);
    IUStbMinting.Signature memory redeemTakerSignature =
      signOrder(ownerPrivateKey, redeemDigest, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BenefactorNotWhitelisted);
    UStbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UStbMintingContract.addWhitelistedBenefactor(owner);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BeneficiaryNotApproved);
    UStbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UStbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder, redeemTakerSignature);
  }

  function test_whitelisted_beneficiary_whitelist_enabled_transfer_redeem() public {
    vm.prank(benefactor);
    UStbMintingContract.setApprovedBeneficiary(owner, true);
    IUStbMinting.Order memory order = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 3423423,
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      ustb_amount: _ustbToMint,
      collateral_amount: _stETHToDeposit
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UStbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUStbMinting.Route memory route = IUStbMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    IUStbMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUStbMinting.SignatureType.EIP712);
    IERC20(address(stETHToken)).approve(address(UStbMintingContract), _stETHToDeposit);
    vm.stopPrank();

    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    // set the transfer state to WHITELIST_ENABLED
    vm.startPrank(newOwner);
    ustbToken.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    ustbToken.grantRole(keccak256("WHITELISTED_ROLE"), owner);
    vm.stopPrank();

    IUStbMinting.Order memory redeemOrder = IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 44524527,
      benefactor: owner,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      ustb_amount: _ustbToMint
    });

    // taker
    vm.startPrank(owner);
    ustbToken.approve(address(UStbMintingContract), _ustbToMint);

    bytes32 redeemDigest = UStbMintingContract.hashOrder(redeemOrder);
    IUStbMinting.Signature memory redeemTakerSignature =
      signOrder(ownerPrivateKey, redeemDigest, IUStbMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BenefactorNotWhitelisted);
    UStbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UStbMintingContract.addWhitelistedBenefactor(owner);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BeneficiaryNotApproved);
    UStbMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UStbMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder, redeemTakerSignature);
  }
}
