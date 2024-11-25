// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../USDtbMinting.utils.sol";

contract USDtbMintingContractSigningTest is USDtbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_multi_sig_eip_1271_mint() public {
    IUSDtbMinting.Order memory order = createOrder();
    IUSDtbMinting.Route memory route = createRoute();
    bytes32 digest1 = USDtbMintingContract.hashOrder(order);

    approveERC20(owner);

    submitFirstSignature(digest1);

    vm.prank(minter);
    vm.expectRevert(InvalidEIP1271Signature);
    USDtbMintingContract.mint(
      order, route, signOrder(smartContractSigner1PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP1271)
    );

    submitSecondSignature(digest1);

    vm.prank(minter);
    USDtbMintingContract.mint(
      order, route, signOrder(smartContractSigner2PrivateKey, digest1, IUSDtbMinting.SignatureType.EIP1271)
    );

    assertEq(stETHToken.balanceOf(address(MultiSigWalletBenefactor)), 0);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(address(MultiSigWalletBenefactor)), _usdtbToMint);
  }

  function createOrder() internal view returns (IUSDtbMinting.Order memory) {
    return IUSDtbMinting.Order({
      order_type: IUSDtbMinting.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 1,
      benefactor: mockMultiSigWallet,
      beneficiary: mockMultiSigWallet,
      collateral_asset: address(stETHToken),
      usdtb_amount: _usdtbToMint,
      collateral_amount: _stETHToDeposit
    });
  }

  function createRoute() internal view returns (IUSDtbMinting.Route memory) {
    address[] memory targets = new address[](1);
    targets[0] = address(USDtbMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    return IUSDtbMinting.Route({addresses: targets, ratios: ratios});
  }

  function signMessage(uint256 privateKey) internal view returns (bytes memory) {
    bytes32 messageHash =
      keccak256(abi.encodePacked(address(stETHToken), address(USDtbMintingContract), _stETHToDeposit));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
    return _packRsv(r, s, v);
  }

  function approveERC20(address approver) internal {
    vm.prank(approver);
    MultiSigWalletBenefactor.approveERC20(address(stETHToken), address(USDtbMintingContract), _stETHToDeposit);
  }

  function submitFirstSignature(bytes32 digest) internal {
    vm.startPrank(smartContractSigner1);
    IUSDtbMinting.Signature memory signature =
      signOrder(smartContractSigner1PrivateKey, digest, IUSDtbMinting.SignatureType.EIP1271);
    MultiSigWalletBenefactor.submitSignature(digest, signature.signature_bytes);
    vm.stopPrank();
  }

  function submitSecondSignature(bytes32 digest) internal {
    vm.startPrank(smartContractSigner2);
    IUSDtbMinting.Signature memory signature =
      signOrder(smartContractSigner2PrivateKey, digest, IUSDtbMinting.SignatureType.EIP1271);
    MultiSigWalletBenefactor.submitSignature(digest, signature.signature_bytes);
    vm.stopPrank();
  }
}
