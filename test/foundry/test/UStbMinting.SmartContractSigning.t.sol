// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UStbMinting.utils.sol";

contract UStbMintingContractSigningTest is UStbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_multi_sig_eip_1271_mint() public {
    IUStbMinting.Order memory order = createOrder();
    IUStbMinting.Route memory route = createRoute();
    bytes32 digest1 = UStbMintingContract.hashOrder(order);

    approveERC20(owner);

    submitFirstSignature(digest1);

    vm.prank(minter);
    vm.expectRevert(InvalidEIP1271Signature);
    UStbMintingContract.mint(
      order, route, signOrder(smartContractSigner1PrivateKey, digest1, IUStbMinting.SignatureType.EIP1271)
    );

    submitSecondSignature(digest1);

    vm.prank(minter);
    UStbMintingContract.mint(
      order, route, signOrder(smartContractSigner2PrivateKey, digest1, IUStbMinting.SignatureType.EIP1271)
    );

    assertEq(stETHToken.balanceOf(address(MultiSigWalletBenefactor)), 0);
    assertEq(stETHToken.balanceOf(address(UStbMintingContract)), _stETHToDeposit);
    assertEq(ustbToken.balanceOf(address(MultiSigWalletBenefactor)), _ustbToMint);
  }

  function createOrder() internal view returns (IUStbMinting.Order memory) {
    return IUStbMinting.Order({
      order_type: IUStbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 1,
      benefactor: mockMultiSigWallet,
      beneficiary: mockMultiSigWallet,
      collateral_asset: address(stETHToken),
      ustb_amount: _ustbToMint,
      collateral_amount: _stETHToDeposit
    });
  }

  function createRoute() internal view returns (IUStbMinting.Route memory) {
    address[] memory targets = new address[](1);
    targets[0] = address(UStbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    return IUStbMinting.Route({addresses: targets, ratios: ratios});
  }

  function signMessage(uint256 privateKey) internal view returns (bytes memory) {
    bytes32 messageHash =
      keccak256(abi.encodePacked(address(stETHToken), address(UStbMintingContract), _stETHToDeposit));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
    return _packRsv(r, s, v);
  }

  function approveERC20(address approver) internal {
    vm.prank(approver);
    MultiSigWalletBenefactor.approveERC20(address(stETHToken), address(UStbMintingContract), _stETHToDeposit);
  }

  function submitFirstSignature(bytes32 digest) internal {
    vm.startPrank(smartContractSigner1);
    IUStbMinting.Signature memory signature =
      signOrder(smartContractSigner1PrivateKey, digest, IUStbMinting.SignatureType.EIP1271);
    MultiSigWalletBenefactor.submitSignature(digest, signature.signature_bytes);
    vm.stopPrank();
  }

  function submitSecondSignature(bytes32 digest) internal {
    vm.startPrank(smartContractSigner2);
    IUStbMinting.Signature memory signature =
      signOrder(smartContractSigner2PrivateKey, digest, IUStbMinting.SignatureType.EIP1271);
    MultiSigWalletBenefactor.submitSignature(digest, signature.signature_bytes);
    vm.stopPrank();
  }
}
