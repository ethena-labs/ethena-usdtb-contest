// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UStbMinting.utils.sol";

contract UStbMintingBlockLimitsTest is UStbMintingUtils {
  /**
   * Max mint per block tests
   */

  // Ensures that the minted per block amount raises accordingly
  // when multiple mints are performed
  function test_multiple_mints() public {
    uint128 maxMintAmount = tokenConfig[0].maxMintPerBlock;
    uint128 firstMintAmount = maxMintAmount / 4;
    uint128 secondMintAmount = maxMintAmount / 2;
    (IUStbMinting.Order memory aOrder, IUStbMinting.Signature memory aTakerSignature, IUStbMinting.Route memory aRoute)
    = mint_setup(firstMintAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    UStbMintingContract.mint(aOrder, aRoute, aTakerSignature);

    vm.prank(owner);
    stETHToken.mint(_stETHToDeposit, benefactor);

    (IUStbMinting.Order memory bOrder, IUStbMinting.Signature memory bTakerSignature, IUStbMinting.Route memory bRoute)
    = mint_setup(secondMintAmount, _stETHToDeposit, stETHToken, 2, true);

    vm.prank(minter);
    UStbMintingContract.mint(bOrder, bRoute, bTakerSignature);

    (uint128 mintedPerBlock,) = UStbMintingContract.totalPerBlockPerAsset(block.number, address(stETHToken));

    assertEq(mintedPerBlock, firstMintAmount + secondMintAmount, "Incorrect minted amount");
    assertTrue(mintedPerBlock < maxMintAmount, "Mint amount exceeded without revert");
  }

  function test_fuzz_maxMint_perBlock_exceeded_revert(uint128 excessiveMintAmount) public {
    // This amount is always greater than the allowed max mint per block
    vm.assume(excessiveMintAmount > tokenConfig[0].maxMintPerBlock);

    maxMint_perBlock_exceeded_revert(excessiveMintAmount);
  }

  function test_fuzz_mint_maxMint_perBlock_exceeded_revert(uint128 excessiveMintAmount) public {
    vm.assume(excessiveMintAmount > tokenConfig[0].maxMintPerBlock);
    (IUStbMinting.Order memory mintOrder, IUStbMinting.Signature memory takerSignature, IUStbMinting.Route memory route)
    = mint_setup(excessiveMintAmount, _stETHToDeposit, stETHToken, 1, false);

    // maker
    vm.startPrank(minter);
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(ustbToken.balanceOf(beneficiary), 0);

    vm.expectRevert(MaxMintPerBlockExceeded);
    // minter passes in permit signature data
    UStbMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(
      stETHToken.balanceOf(benefactor),
      _stETHToDeposit,
      "The benefactor stEth balance should be the same as the minted stEth"
    );
    assertEq(ustbToken.balanceOf(beneficiary), 0, "The beneficiary UStb balance should be 0");
  }

  function test_fuzz_nextBlock_mint_is_zero(uint128 mintAmount) public {
    vm.assume(mintAmount < tokenConfig[0].maxMintPerBlock && mintAmount > 0);
    (IUStbMinting.Order memory order, IUStbMinting.Signature memory takerSignature, IUStbMinting.Route memory route) =
      mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    UStbMintingContract.mint(order, route, takerSignature);

    vm.roll(block.number + 1);

    (uint128 mintedPerBlock,) = UStbMintingContract.totalPerBlockPerAsset(block.number, address(stETHToken));

    assertEq(mintedPerBlock, 0, "The minted amount should reset to 0 in the next block");
  }

  function test_fuzz_maxMint_perBlock_setter(uint128 newMaxMintPerBlock) public {
    vm.assume(newMaxMintPerBlock > 0);

    uint128 oldMaxMintPerBlock = tokenConfig[0].maxMintPerBlock;

    vm.prank(owner);
    vm.expectEmit();
    emit MaxMintPerBlockChanged(oldMaxMintPerBlock, newMaxMintPerBlock, address(stETHToken));

    UStbMintingContract.setMaxMintPerBlock(newMaxMintPerBlock, address(stETHToken));

    (,, uint128 maxMintPerBlock,) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxMintPerBlock, newMaxMintPerBlock, "The max mint per block setter failed");
  }

  function test_global_mint_limit_versus_local_perBlock() public {
    uint128 maxMintAmount = tokenConfig[0].maxMintPerBlock;
    uint128 firstMintAmount = maxMintAmount / 4;
    (IUStbMinting.Order memory aOrder, IUStbMinting.Signature memory aTakerSignature, IUStbMinting.Route memory aRoute)
    = mint_setup(firstMintAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.startPrank(owner);
    stETHToken.mint(_stETHToDeposit, benefactor);

    // within per asset but NOT global limit
    vm.startPrank(owner);
    UStbMintingContract.setMaxMintPerBlock(maxMintAmount, address(stETHToken));
    UStbMintingContract.setGlobalMaxMintPerBlock(maxMintAmount / 5);
    vm.stopPrank();

    vm.startPrank(minter);
    vm.expectRevert(GlobalMaxMintPerBlockExceeded);
    UStbMintingContract.mint(aOrder, aRoute, aTakerSignature);
    vm.stopPrank();

    // within global but NOT per asset limit
    vm.startPrank(owner);
    UStbMintingContract.setGlobalMaxMintPerBlock(maxMintAmount);
    UStbMintingContract.setMaxMintPerBlock(firstMintAmount / 2, address(stETHToken));
    vm.stopPrank();

    vm.startPrank(minter);
    vm.expectRevert(MaxMintPerBlockExceeded);
    UStbMintingContract.mint(aOrder, aRoute, aTakerSignature);
    vm.stopPrank();

    // within global and per asset limit
    vm.startPrank(owner);
    UStbMintingContract.setMaxMintPerBlock(firstMintAmount, address(stETHToken));
    UStbMintingContract.setGlobalMaxMintPerBlock(firstMintAmount);
    vm.stopPrank();

    vm.prank(minter);
    UStbMintingContract.mint(aOrder, aRoute, aTakerSignature);
  }

  /**
   * Max redeem per block tests
   */

  // Ensures that the redeemed per block amount raises accordingly
  // when multiple mints are performed
  function test_multiple_redeem() public {
    uint128 maxRedeemAmount = tokenConfig[0].maxRedeemPerBlock;
    uint128 firstRedeemAmount = maxRedeemAmount / 4;
    uint128 secondRedeemAmount = maxRedeemAmount / 2;

    (IUStbMinting.Order memory redeemOrder, IUStbMinting.Signature memory takerSignature2) =
      redeem_setup(firstRedeemAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(redeemer);
    UStbMintingContract.redeem(redeemOrder, takerSignature2);

    vm.prank(owner);
    stETHToken.mint(_stETHToDeposit, benefactor);

    (IUStbMinting.Order memory bRedeemOrder, IUStbMinting.Signature memory bTakerSignature2) =
      redeem_setup(secondRedeemAmount, _stETHToDeposit, stETHToken, 2, true);

    vm.prank(redeemer);
    UStbMintingContract.redeem(bRedeemOrder, bTakerSignature2);

    (uint128 mintedPerBlock,) = UStbMintingContract.totalPerBlockPerAsset(block.number, address(stETHToken));

    assertEq(mintedPerBlock, firstRedeemAmount + secondRedeemAmount, "Incorrect minted amount");

    (, uint128 redeemedPerBlock2) = UStbMintingContract.totalPerBlockPerAsset(block.number, address(stETHToken));
    assertTrue(redeemedPerBlock2 < maxRedeemAmount, "Redeem amount exceeded without revert");
  }

  function test_fuzz_maxRedeem_perBlock_exceeded_revert(uint128 excessiveRedeemAmount) public {
    // This amount is always greater than the allowed max redeem per block
    vm.assume(excessiveRedeemAmount > tokenConfig[0].maxRedeemPerBlock);

    // excessive redeem amount greater than max mint/redeem per block for stETH but within global limit
    vm.startPrank(owner);
    UStbMintingContract.setGlobalMaxMintPerBlock(excessiveRedeemAmount);
    UStbMintingContract.setGlobalMaxRedeemPerBlock(excessiveRedeemAmount);
    vm.stopPrank();

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

  function test_fuzz_nextBlock_redeem_is_zero(uint128 redeemAmount) public {
    vm.assume(redeemAmount < tokenConfig[0].maxRedeemPerBlock && redeemAmount > 0);
    (IUStbMinting.Order memory redeemOrder, IUStbMinting.Signature memory takerSignature2) =
      redeem_setup(redeemAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.startPrank(redeemer);
    UStbMintingContract.redeem(redeemOrder, takerSignature2);

    vm.roll(block.number + 1);

    (, uint128 redeemedPerBlock) = UStbMintingContract.totalPerBlockPerAsset(block.number, address(stETHToken));

    assertEq(redeemedPerBlock, 0, "The redeemed amount should reset to 0 in the next block");
    vm.stopPrank();
  }

  function test_fuzz_maxRedeem_perBlock_setter(uint128 newMaxRedeemPerBlock) public {
    vm.assume(newMaxRedeemPerBlock > 0);

    uint128 oldMaxRedeemPerBlock = tokenConfig[0].maxMintPerBlock;

    vm.prank(owner);
    vm.expectEmit();
    emit MaxRedeemPerBlockChanged(oldMaxRedeemPerBlock, newMaxRedeemPerBlock, address(stETHToken));
    UStbMintingContract.setMaxRedeemPerBlock(newMaxRedeemPerBlock, address(stETHToken));

    (,,, uint128 maxRedeemPerBlock) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock, newMaxRedeemPerBlock, "The max redeem per block setter failed");
  }
}
