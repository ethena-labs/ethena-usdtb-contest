// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "forge-std/console.sol";
import "./USDtbMintingBaseSetup.sol";

// These functions are reused across multiple files
contract USDtbMintingUtils is USDtbMintingBaseSetup {
  function maxMint_perBlock_exceeded_revert(uint128 excessiveMintAmount) public {
    // This amount is always greater than the allowed max mint per block
    (,, uint128 maxMintPerBlock,) = USDtbMintingContract.tokenConfig(address(stETHToken));

    vm.assume(excessiveMintAmount > (maxMintPerBlock));
    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature, IUSDtbMinting.Route memory route) =
      mint_setup(excessiveMintAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    vm.expectRevert(MaxMintPerBlockExceeded);
    USDtbMintingContract.mint(order, route, takerSignature);

    assertEq(usdtbToken.balanceOf(beneficiary), 0, "The beneficiary balance should be 0");
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), 0, "The usdtb minting stETH balance should be 0");
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in stETH balance");
  }

  function maxRedeem_perBlock_exceeded_revert(uint128 excessiveRedeemAmount) public {
    // Set the max mint per block to the same value as the max redeem in order to get to the redeem
    vm.prank(owner);
    USDtbMintingContract.setMaxMintPerBlock(excessiveRedeemAmount, address(stETHToken));

    (IUSDtbMinting.Order memory redeemOrder, IUSDtbMinting.Signature memory takerSignature2) =
      redeem_setup(excessiveRedeemAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.startPrank(redeemer);
    vm.expectRevert(MaxRedeemPerBlockExceeded);
    USDtbMintingContract.redeem(redeemOrder, takerSignature2);

    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), _stETHToDeposit, "Mismatch in stETH balance");
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in stETH balance");
    assertEq(usdtbToken.balanceOf(beneficiary), excessiveRedeemAmount, "Mismatch in USDtb balance");

    vm.stopPrank();
  }

  function executeMint(IERC20 collateralAsset) public {
    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature, IUSDtbMinting.Route memory route) =
      mint_setup(_usdtbToMint, _stETHToDeposit, collateralAsset, 1, false);

    vm.prank(minter);
    USDtbMintingContract.mint(order, route, takerSignature);
  }

  function executeRedeem(IERC20 collateralAsset) public {
    (IUSDtbMinting.Order memory redeemOrder, IUSDtbMinting.Signature memory takerSignature2) =
      redeem_setup(_usdtbToMint, _stETHToDeposit, collateralAsset, 1, false);
    vm.prank(redeemer);
    USDtbMintingContract.redeem(redeemOrder, takerSignature2);
  }
}
