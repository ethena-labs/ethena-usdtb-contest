// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "forge-std/console.sol";
import "./UStbMintingBaseSetup.sol";

// These functions are reused across multiple files
contract UStbMintingUtils is UStbMintingBaseSetup {
    function maxMint_perBlock_exceeded_revert(uint128 excessiveMintAmount) public {
        // This amount is always greater than the allowed max mint per block
        (,, uint128 maxMintPerBlock,) = UStbMintingContract.tokenConfig(address(stETHToken));

        vm.assume(excessiveMintAmount > (maxMintPerBlock));
        (
            IUStbMinting.Order memory order,
            IUStbMinting.Signature memory takerSignature,
            IUStbMinting.Route memory route
        ) = mint_setup(excessiveMintAmount, _stETHToDeposit, stETHToken, 1, false);

        vm.prank(minter);
        vm.expectRevert(MaxMintPerBlockExceeded);
        UStbMintingContract.mint(order, route, takerSignature);

        assertEq(ustbToken.balanceOf(beneficiary), 0, "The beneficiary balance should be 0");
        assertEq(stETHToken.balanceOf(address(UStbMintingContract)), 0, "The ustb minting stETH balance should be 0");
        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in stETH balance");
    }

    function maxRedeem_perBlock_exceeded_revert(uint128 excessiveRedeemAmount) public {
        // Set the max mint per block to the same value as the max redeem in order to get to the redeem
        vm.prank(owner);
        UStbMintingContract.setMaxMintPerBlock(excessiveRedeemAmount, address(stETHToken));

        (IUStbMinting.Order memory redeemOrder, IUStbMinting.Signature memory takerSignature2) =
                        redeem_setup(excessiveRedeemAmount, _stETHToDeposit, stETHToken, 1, false);

        vm.startPrank(redeemer);
        vm.expectRevert(MaxRedeemPerBlockExceeded);
        UStbMintingContract.redeem(redeemOrder, takerSignature2);

        assertEq(stETHToken.balanceOf(address(UStbMintingContract)), _stETHToDeposit, "Mismatch in stETH balance");
        assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in stETH balance");
        assertEq(ustbToken.balanceOf(beneficiary), excessiveRedeemAmount, "Mismatch in UStb balance");

        vm.stopPrank();
    }

    function executeMint(IERC20 collateralAsset) public {
        (
            IUStbMinting.Order memory order,
            IUStbMinting.Signature memory takerSignature,
            IUStbMinting.Route memory route
        ) = mint_setup(_ustbToMint, _stETHToDeposit, collateralAsset, 1, false);

        vm.prank(minter);
        UStbMintingContract.mint(order, route, takerSignature);
    }

    function executeRedeem(IERC20 collateralAsset) public {
        (IUStbMinting.Order memory redeemOrder, IUStbMinting.Signature memory takerSignature2) =
                        redeem_setup(_ustbToMint, _stETHToDeposit, collateralAsset, 1, false);
        vm.prank(redeemer);
        UStbMintingContract.redeem(redeemOrder, takerSignature2);
    }
}
