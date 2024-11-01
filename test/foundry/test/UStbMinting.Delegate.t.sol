// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../UStbMinting.utils.sol";

contract UStbMintingDelegateTest is UStbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function testDelegateSuccessfulMint() public {
    (IUStbMinting.Order memory order,, IUStbMinting.Route memory route) =
      mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    // request delegation
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, benefactor);
    UStbMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUStbMinting.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    bytes32 digest1 = UStbMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, benefactor);
    UStbMintingContract.confirmDelegatedSigner(benefactor);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUStbMinting.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    IUStbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUStbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary UStb balance before mint");

    vm.prank(minter);
    UStbMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance after mint");
    assertEq(ustbToken.balanceOf(beneficiary), _ustbToMint, "Mismatch in beneficiary UStb balance after mint");
  }

  function testDelegateFailureMint() public {
    (IUStbMinting.Order memory order,, IUStbMinting.Route memory route) =
      mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    bytes32 digest1 = UStbMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectRevert(IUStbMinting.DelegationNotInitiated.selector);
    UStbMintingContract.confirmDelegatedSigner(benefactor);

    vm.prank(trader2);
    IUStbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUStbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary UStb balance before mint");

    // assert that the delegation is rejected
    assertEq(
      uint256(UStbMintingContract.delegatedSigner(minter, trader2)),
      uint256(IUStbMinting.DelegatedSignerStatus.REJECTED),
      "The delegation status should be rejected"
    );

    vm.prank(minter);
    vm.expectRevert(InvalidEIP712Signature);
    UStbMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary UStb balance after mint");
  }

  function testDelegateSuccessfulRedeem() public {
    (IUStbMinting.Order memory order,) = redeem_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    // request delegation
    vm.prank(beneficiary);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, beneficiary);
    UStbMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, beneficiary)),
      uint256(IUStbMinting.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    bytes32 digest1 = UStbMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, beneficiary);
    UStbMintingContract.confirmDelegatedSigner(beneficiary);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, beneficiary)),
      uint256(IUStbMinting.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    IUStbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUStbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(ustbToken.balanceOf(beneficiary), _ustbToMint, "Mismatch in beneficiary UStb balance before mint");

    vm.prank(redeemer);
    UStbMintingContract.redeem(order, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary UStb balance after mint");
  }

  function testDelegateFailureRedeem() public {
    (IUStbMinting.Order memory order,) = redeem_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUStbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUStbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(ustbToken.balanceOf(beneficiary), _ustbToMint, "Mismatch in beneficiary UStb balance before mint");

    // assert that the delegation is rejected
    assertEq(
      uint256(UStbMintingContract.delegatedSigner(redeemer, trader2)),
      uint256(IUStbMinting.DelegatedSignerStatus.REJECTED),
      "The delegation status should be rejected"
    );

    vm.prank(redeemer);
    vm.expectRevert(InvalidEIP712Signature);
    UStbMintingContract.redeem(order, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance after mint");
    assertEq(ustbToken.balanceOf(beneficiary), _ustbToMint, "Mismatch in beneficiary UStb balance after mint");
  }

  function testCanUndelegate() public {
    (IUStbMinting.Order memory order,, IUStbMinting.Route memory route) =
      mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    // delegate request
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, benefactor);
    UStbMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUStbMinting.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    // accept the delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, benefactor);
    UStbMintingContract.confirmDelegatedSigner(benefactor);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUStbMinting.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    // remove the delegation
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerRemoved(trader2, benefactor);
    UStbMintingContract.removeDelegatedSigner(trader2);

    assertEq(
      uint256(UStbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUStbMinting.DelegatedSignerStatus.REJECTED),
      "The delegation status should be accepted"
    );

    bytes32 digest1 = UStbMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUStbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUStbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary UStb balance before mint");

    vm.prank(minter);
    vm.expectRevert(InvalidEIP712Signature);
    UStbMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UStbMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(ustbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary UStb balance after mint");
  }
}
