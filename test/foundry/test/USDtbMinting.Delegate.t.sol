// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../USDtbMinting.utils.sol";

contract USDtbMintingDelegateTest is USDtbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function testDelegateSuccessfulMint() public {
    (IUSDtbMinting.Order memory order,, IUSDtbMinting.Route memory route) =
      mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    // request delegation
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, benefactor);
    USDtbMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, benefactor);
    USDtbMintingContract.confirmDelegatedSigner(benefactor);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    IUSDtbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDtb balance before mint");

    vm.prank(minter);
    USDtbMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usdtbToken.balanceOf(beneficiary), _usdtbToMint, "Mismatch in beneficiary USDtb balance after mint");
  }

  function testDelegateFailureMint() public {
    (IUSDtbMinting.Order memory order,, IUSDtbMinting.Route memory route) =
      mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectRevert(IUSDtbMinting.DelegationNotInitiated.selector);
    USDtbMintingContract.confirmDelegatedSigner(benefactor);

    vm.prank(trader2);
    IUSDtbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDtb balance before mint");

    // assert that the delegation is rejected
    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(minter, trader2)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.REJECTED),
      "The delegation status should be rejected"
    );

    vm.prank(minter);
    vm.expectRevert(InvalidEIP712Signature);
    USDtbMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDtb balance after mint");
  }

  function testDelegateSuccessfulRedeem() public {
    (IUSDtbMinting.Order memory order,) = redeem_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    // request delegation
    vm.prank(beneficiary);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, beneficiary);
    USDtbMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, beneficiary)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, beneficiary);
    USDtbMintingContract.confirmDelegatedSigner(beneficiary);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, beneficiary)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    IUSDtbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(usdtbToken.balanceOf(beneficiary), _usdtbToMint, "Mismatch in beneficiary USDtb balance before mint");

    vm.prank(redeemer);
    USDtbMintingContract.redeem(order, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDtb balance after mint");
  }

  function testDelegateFailureRedeem() public {
    (IUSDtbMinting.Order memory order,) = redeem_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUSDtbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(usdtbToken.balanceOf(beneficiary), _usdtbToMint, "Mismatch in beneficiary USDtb balance before mint");

    // assert that the delegation is rejected
    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(redeemer, trader2)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.REJECTED),
      "The delegation status should be rejected"
    );

    vm.prank(redeemer);
    vm.expectRevert(InvalidEIP712Signature);
    USDtbMintingContract.redeem(order, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usdtbToken.balanceOf(beneficiary), _usdtbToMint, "Mismatch in beneficiary USDtb balance after mint");
  }

  function testCanUndelegate() public {
    (IUSDtbMinting.Order memory order,, IUSDtbMinting.Route memory route) =
      mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    // delegate request
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, benefactor);
    USDtbMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    // accept the delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, benefactor);
    USDtbMintingContract.confirmDelegatedSigner(benefactor);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    // remove the delegation
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerRemoved(trader2, benefactor);
    USDtbMintingContract.removeDelegatedSigner(trader2);

    assertEq(
      uint256(USDtbMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUSDtbMinting.DelegatedSignerStatus.REJECTED),
      "The delegation status should be accepted"
    );

    bytes32 digest1 = USDtbMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUSDtbMinting.Signature memory trader2Sig = signOrder(trader2PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDtb balance before mint");

    vm.prank(minter);
    vm.expectRevert(InvalidEIP712Signature);
    USDtbMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(USDtbMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usdtbToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDtb balance after mint");
  }
}
