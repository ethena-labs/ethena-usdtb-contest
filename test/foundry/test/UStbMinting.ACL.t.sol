// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UStbMinting.utils.sol";
import "../../../contracts/ustb/IUStbMinting.sol";
import "../../../contracts/interfaces/ISingleAdminAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../contracts/ustb/IUStbMinting.sol";

contract UStbMintingACLTest is UStbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_redeem_notRedeemer_revert() public {
    (IUStbMinting.Order memory redeemOrder, IUStbMinting.Signature memory takerSignature2) =
      redeem_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.startPrank(minter);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(minter), " is missing role ", vm.toString(redeemerRole)
        )
      )
    );
    UStbMintingContract.redeem(redeemOrder, takerSignature2);
  }

  function test_fuzz_notMinter_cannot_mint(address nonMinter) public {
    (
      IUStbMinting.Order memory mintOrder,
      IUStbMinting.Signature memory takerSignature,
      IUStbMinting.Route memory route
    ) = mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.assume(nonMinter != minter);
    vm.startPrank(nonMinter);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(nonMinter), " is missing role ", vm.toString(minterRole)
        )
      )
    );
    UStbMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(ustbToken.balanceOf(beneficiary), 0);
  }

  function test_fuzz_nonOwner_cannot_add_supportedAsset_revert(address nonOwner) public {
    vm.assume(nonOwner != owner);
    address asset = address(20);
    vm.expectRevert();
    vm.prank(nonOwner);
    IUStbMinting.TokenConfig memory tokenConfig = IUStbMinting.TokenConfig(
      IUStbMinting.TokenType.ASSET, true, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK
    );
    UStbMintingContract.addSupportedAsset(asset, tokenConfig);
    assertFalse(UStbMintingContract.isSupportedAsset(asset));
  }

  function test_fuzz_nonOwner_cannot_remove_supportedAsset_revert(address nonOwner) public {
    vm.assume(nonOwner != owner);
    address asset = address(20);
    vm.prank(owner);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    IUStbMinting.TokenConfig memory tokenConfig = IUStbMinting.TokenConfig(
      IUStbMinting.TokenType.ASSET, true, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK
    );
    UStbMintingContract.addSupportedAsset(asset, tokenConfig);
    assertTrue(UStbMintingContract.isSupportedAsset(asset));

    vm.expectRevert();
    vm.prank(nonOwner);
    UStbMintingContract.removeSupportedAsset(asset);
    assertTrue(UStbMintingContract.isSupportedAsset(asset));
  }

  function test_collateralManager_canTransfer_custody() public {
    vm.startPrank(owner);
    stETHToken.mint(1000, address(UStbMintingContract));
    UStbMintingContract.addCustodianAddress(beneficiary);
    UStbMintingContract.grantRole(collateralManagerRole, minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectEmit(true, true, true, true);
    emit CustodyTransfer(beneficiary, address(stETHToken), 1000);
    UStbMintingContract.transferToCustody(beneficiary, address(stETHToken), 1000);
    assertEq(stETHToken.balanceOf(beneficiary), 1000);
    assertEq(stETHToken.balanceOf(address(UStbMintingContract)), 0);
  }

  function test_collateralManager_canTransferNative_custody() public {
    vm.startPrank(owner);
    vm.deal(address(UStbMintingContract), 1000);
    UStbMintingContract.addCustodianAddress(beneficiary);
    UStbMintingContract.grantRole(collateralManagerRole, minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectEmit(true, true, true, true);
    emit CustodyTransfer(beneficiary, address(NATIVE_TOKEN), 1000);
    UStbMintingContract.transferToCustody(beneficiary, address(NATIVE_TOKEN), 1000);
    assertEq(beneficiary.balance, 1000);
    assertEq(address(UStbMintingContract).balance, 0);
  }

  function test_collateralManager_cannotTransfer_zeroAddress() public {
    vm.startPrank(owner);
    stETHToken.mint(1000, address(UStbMintingContract));
    UStbMintingContract.addCustodianAddress(beneficiary);
    UStbMintingContract.grantRole(collateralManagerRole, minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectRevert(IUStbMinting.InvalidAddress.selector);
    UStbMintingContract.transferToCustody(address(0), address(stETHToken), 1000);
  }

  function test_fuzz_nonCollateralManager_cannot_transferCustody_revert(address nonCollateralManager) public {
    vm.assume(
      nonCollateralManager != collateralManager && nonCollateralManager != owner && nonCollateralManager != address(0)
    );
    stETHToken.mint(1000, address(UStbMintingContract));

    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(nonCollateralManager),
          " is missing role ",
          vm.toString(collateralManagerRole)
        )
      )
    );
    vm.prank(nonCollateralManager);
    UStbMintingContract.transferToCustody(beneficiary, address(stETHToken), 1000);
  }

  /**
   * Gatekeeper tests
   */
  function test_gatekeeper_can_remove_minter() public {
    vm.prank(gatekeeper);

    UStbMintingContract.removeMinterRole(minter);
    assertFalse(UStbMintingContract.hasRole(minterRole, minter));
  }

  function test_gatekeeper_can_remove_redeemer() public {
    vm.prank(gatekeeper);

    UStbMintingContract.removeRedeemerRole(redeemer);
    assertFalse(UStbMintingContract.hasRole(redeemerRole, redeemer));
  }

  function test_gatekeeper_can_remove_collateral_manager() public {
    vm.prank(gatekeeper);

    UStbMintingContract.removeCollateralManagerRole(collateralManager);
    assertFalse(UStbMintingContract.hasRole(collateralManagerRole, collateralManager));
  }

  function test_fuzz_not_gatekeeper_cannot_remove_minter_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UStbMintingContract.removeMinterRole(minter);
    assertTrue(UStbMintingContract.hasRole(minterRole, minter));
  }

  function test_fuzz_not_gatekeeper_cannot_remove_redeemer_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UStbMintingContract.removeRedeemerRole(redeemer);
    assertTrue(UStbMintingContract.hasRole(redeemerRole, redeemer));
  }

  function test_fuzz_not_gatekeeper_cannot_remove_collateral_manager_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UStbMintingContract.removeCollateralManagerRole(collateralManager);
    assertTrue(UStbMintingContract.hasRole(collateralManagerRole, collateralManager));
  }

  function test_gatekeeper_cannot_add_minters_revert() public {
    vm.startPrank(gatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(gatekeeper), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.grantRole(minterRole, bob);
    assertFalse(UStbMintingContract.hasRole(minterRole, bob), "Bob should lack the minter role");
  }

  function test_gatekeeper_cannot_add_collateral_managers_revert() public {
    vm.startPrank(gatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(gatekeeper), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.grantRole(collateralManagerRole, bob);
    assertFalse(UStbMintingContract.hasRole(collateralManagerRole, bob), "Bob should lack the collateralManager role");
  }

  function test_gatekeeper_can_disable_mintRedeem() public {
    vm.startPrank(gatekeeper);
    UStbMintingContract.disableMintRedeem();

    (
      IUStbMinting.Order memory order,
      IUStbMinting.Signature memory takerSignature,
      IUStbMinting.Route memory route
    ) = mint_setup(_ustbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    vm.expectRevert(GlobalMaxMintPerBlockExceeded);
    UStbMintingContract.mint(order, route, takerSignature);

    vm.prank(redeemer);
    vm.expectRevert(GlobalMaxRedeemPerBlockExceeded);
    UStbMintingContract.redeem(order, takerSignature);

    (uint128 globalMaxMintPerBlock, uint128 globalMaxRedeemPerBlock) = UStbMintingContract.globalConfig();

    assertEq(globalMaxMintPerBlock, 0, "Minting should be disabled");
    assertEq(globalMaxRedeemPerBlock, 0, "Redeeming should be disabled");
  }

  // Ensure that the gatekeeper is not allowed to enable/modify the minting
  function test_gatekeeper_cannot_enable_mint_revert() public {
    test_fuzz_nonAdmin_cannot_enable_mint_revert(gatekeeper);
  }

  // Ensure that the gatekeeper is not allowed to enable/modify the redeeming
  function test_gatekeeper_cannot_enable_redeem_revert() public {
    test_fuzz_nonAdmin_cannot_enable_redeem_revert(gatekeeper);
  }

  function test_fuzz_not_gatekeeper_cannot_disable_mintRedeem_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UStbMintingContract.disableMintRedeem();

    assertTrue(tokenConfig[0].maxMintPerBlock > 0);
    assertTrue(tokenConfig[0].maxRedeemPerBlock > 0);
  }

  /**
   * Admin tests
   */
  function test_admin_can_disable_mint(bool performCheckMint) public {
    vm.prank(owner);
    UStbMintingContract.setMaxMintPerBlock(0, address(stETHToken));

    if (performCheckMint) maxMint_perBlock_exceeded_revert(1e18);

    (,, uint128 maxMintPerBlock,) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxMintPerBlock, 0, "The minting should be disabled");
  }

  function test_admin_can_disable_redeem(bool performCheckRedeem) public {
    vm.prank(owner);
    UStbMintingContract.setMaxRedeemPerBlock(0, address(stETHToken));

    if (performCheckRedeem) maxRedeem_perBlock_exceeded_revert(1e18);

    (,,, uint128 maxRedeemPerBlock) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock, 0, "The redeem should be disabled");
  }

  function test_admin_can_enable_mint() public {
    vm.startPrank(owner);
    UStbMintingContract.setMaxMintPerBlock(0, address(stETHToken));

    (,, uint128 maxMintPerBlock1,) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxMintPerBlock1, 0, "The minting should be disabled");

    // Re-enable the minting
    UStbMintingContract.setMaxMintPerBlock(_maxMintPerBlock, address(stETHToken));

    vm.stopPrank();

    executeMint(stETHToken);

    (,, uint128 maxMintPerBlock2,) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertTrue(maxMintPerBlock2 > 0, "The minting should be enabled");
  }

  function test_fuzz_nonAdmin_cannot_enable_mint_revert(address notAdmin) public {
    vm.assume(notAdmin != owner);

    test_admin_can_disable_mint(false);

    vm.prank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.setMaxMintPerBlock(_maxMintPerBlock, address(stETHToken));

    maxMint_perBlock_exceeded_revert(1e18);

    (,, uint128 maxMintPerBlock,) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxMintPerBlock, 0, "The minting should remain disabled");
  }

  function test_fuzz_nonAdmin_cannot_enable_redeem_revert(address notAdmin) public {
    vm.assume(notAdmin != owner);

    test_admin_can_disable_redeem(false);

    vm.prank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock, address(stETHToken));

    maxRedeem_perBlock_exceeded_revert(1e18);

    (,,, uint128 maxRedeemPerBlock) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock, 0, "The redeeming should remain disabled");
  }

  function test_admin_can_enable_redeem() public {
    vm.startPrank(owner);
    UStbMintingContract.setMaxRedeemPerBlock(0, address(stETHToken));

    (,,, uint128 maxRedeemPerBlock1) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock1, 0, "The redeem should be disabled");

    // Re-enable the redeeming
    UStbMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock, address(stETHToken));

    vm.stopPrank();

    executeRedeem(stETHToken);

    (,,, uint128 maxRedeemPerBlock2) = UStbMintingContract.tokenConfig(address(stETHToken));

    assertTrue(maxRedeemPerBlock2 > 0, "The redeeming should be enabled");
  }

  function test_admin_can_add_minter() public {
    vm.startPrank(owner);
    UStbMintingContract.grantRole(minterRole, bob);

    assertTrue(UStbMintingContract.hasRole(minterRole, bob), "Bob should have the minter role");
    vm.stopPrank();
  }

  function test_admin_can_remove_minter() public {
    test_admin_can_add_minter();

    vm.startPrank(owner);
    UStbMintingContract.revokeRole(minterRole, bob);

    assertFalse(UStbMintingContract.hasRole(minterRole, bob), "Bob should no longer have the minter role");

    vm.stopPrank();
  }

  function test_admin_can_add_gatekeeper() public {
    vm.startPrank(owner);
    UStbMintingContract.grantRole(gatekeeperRole, bob);

    assertTrue(UStbMintingContract.hasRole(gatekeeperRole, bob), "Bob should have the gatekeeper role");
    vm.stopPrank();
  }

  function test_admin_can_remove_gatekeeper() public {
    test_admin_can_add_gatekeeper();

    vm.startPrank(owner);
    UStbMintingContract.revokeRole(gatekeeperRole, bob);

    assertFalse(UStbMintingContract.hasRole(gatekeeperRole, bob), "Bob should no longer have the gatekeeper role");

    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_remove_minter(address notAdmin) public {
    test_admin_can_add_minter();

    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.revokeRole(minterRole, bob);

    assertTrue(UStbMintingContract.hasRole(minterRole, bob), "Bob should maintain the minter role");
    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_remove_gatekeeper(address notAdmin) public {
    test_admin_can_add_gatekeeper();

    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.revokeRole(gatekeeperRole, bob);

    assertTrue(UStbMintingContract.hasRole(gatekeeperRole, bob), "Bob should maintain the gatekeeper role");

    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_add_minter(address notAdmin) public {
    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.grantRole(minterRole, bob);

    assertFalse(UStbMintingContract.hasRole(minterRole, bob), "Bob should lack the minter role");
    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_add_gatekeeper(address notAdmin) public {
    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UStbMintingContract.grantRole(gatekeeperRole, bob);

    assertFalse(UStbMintingContract.hasRole(gatekeeperRole, bob), "Bob should lack the gatekeeper role");

    vm.stopPrank();
  }

  function test_base_transferAdmin() public {
    vm.prank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    assertTrue(UStbMintingContract.hasRole(adminRole, owner));
    assertFalse(UStbMintingContract.hasRole(adminRole, newOwner));

    vm.prank(newOwner);
    UStbMintingContract.acceptAdmin();
    assertFalse(UStbMintingContract.hasRole(adminRole, owner));
    assertTrue(UStbMintingContract.hasRole(adminRole, newOwner));
  }

  function test_transferAdmin_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert();
    UStbMintingContract.transferAdmin(randomer);
  }

  function test_grantRole_AdminRoleExternally() public {
    vm.startPrank(randomer);
    vm.expectRevert(
      "AccessControl: account 0xc91041eae7bf78e1040f4abd7b29908651f45546 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UStbMintingContract.grantRole(adminRole, randomer);
    vm.stopPrank();
  }

  function test_revokeRole_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert(
      "AccessControl: account 0xc91041eae7bf78e1040f4abd7b29908651f45546 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UStbMintingContract.revokeRole(adminRole, owner);
  }

  function test_revokeRole_AdminRole() public {
    vm.startPrank(owner);
    vm.expectRevert();
    UStbMintingContract.revokeRole(adminRole, owner);
  }

  function test_renounceRole_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert(InvalidAdminChange);
    UStbMintingContract.renounceRole(adminRole, owner);
  }

  function test_renounceRole_AdminRole() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAdminChange);
    UStbMintingContract.renounceRole(adminRole, owner);
  }

  function test_revoke_AdminRole() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAdminChange);
    UStbMintingContract.revokeRole(adminRole, owner);
  }

  function test_grantRole_nonAdminRole() public {
    vm.prank(owner);
    UStbMintingContract.grantRole(minterRole, randomer);
    assertTrue(UStbMintingContract.hasRole(minterRole, randomer));
  }

  function test_revokeRole_nonAdminRole() public {
    vm.startPrank(owner);
    UStbMintingContract.grantRole(minterRole, randomer);
    UStbMintingContract.revokeRole(minterRole, randomer);
    vm.stopPrank();
    assertFalse(UStbMintingContract.hasRole(minterRole, randomer));
  }

  function test_renounceRole_nonAdminRole() public {
    vm.prank(owner);
    UStbMintingContract.grantRole(minterRole, randomer);
    vm.prank(randomer);
    UStbMintingContract.renounceRole(minterRole, randomer);
    assertFalse(UStbMintingContract.hasRole(minterRole, randomer));
  }

  function testCanRepeatedlyTransferAdmin() public {
    vm.startPrank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    UStbMintingContract.transferAdmin(randomer);
    vm.stopPrank();
  }

  function test_renounceRole_forDifferentAccount() public {
    vm.prank(randomer);
    vm.expectRevert("AccessControl: can only renounce roles for self");
    UStbMintingContract.renounceRole(minterRole, owner);
  }

  function testCancelTransferAdmin() public {
    vm.startPrank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    UStbMintingContract.transferAdmin(address(0));
    vm.stopPrank();
    assertTrue(UStbMintingContract.hasRole(adminRole, owner));
    assertFalse(UStbMintingContract.hasRole(adminRole, address(0)));
    assertFalse(UStbMintingContract.hasRole(adminRole, newOwner));
  }

  function test_admin_cannot_transfer_self() public {
    vm.startPrank(owner);
    vm.expectRevert(InvalidAdminChange);
    UStbMintingContract.transferAdmin(owner);
    vm.stopPrank();
    assertTrue(UStbMintingContract.hasRole(adminRole, owner));
  }

  function testAdminCanCancelTransfer() public {
    vm.startPrank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    UStbMintingContract.transferAdmin(address(0));
    vm.stopPrank();

    vm.prank(newOwner);
    vm.expectRevert(ISingleAdminAccessControl.NotPendingAdmin.selector);
    UStbMintingContract.acceptAdmin();

    assertTrue(UStbMintingContract.hasRole(adminRole, owner));
    assertFalse(UStbMintingContract.hasRole(adminRole, address(0)));
    assertFalse(UStbMintingContract.hasRole(adminRole, newOwner));
  }

  function testOwnershipCannotBeRenounced() public {
    vm.startPrank(owner);
    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    UStbMintingContract.renounceRole(adminRole, owner);

    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    UStbMintingContract.revokeRole(adminRole, owner);
    vm.stopPrank();
    assertEq(UStbMintingContract.owner(), owner);
    assertTrue(UStbMintingContract.hasRole(adminRole, owner));
  }

  function testOwnershipTransferRequiresTwoSteps() public {
    vm.prank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    assertEq(UStbMintingContract.owner(), owner);
    assertTrue(UStbMintingContract.hasRole(adminRole, owner));
    assertNotEq(UStbMintingContract.owner(), newOwner);
    assertFalse(UStbMintingContract.hasRole(adminRole, newOwner));
  }

  function testCanTransferOwnership() public {
    vm.prank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    UStbMintingContract.acceptAdmin();
    assertTrue(UStbMintingContract.hasRole(adminRole, newOwner));
    assertFalse(UStbMintingContract.hasRole(adminRole, owner));
  }

  function testNewOwnerCanPerformOwnerActions() public {
    vm.prank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    vm.startPrank(newOwner);
    UStbMintingContract.acceptAdmin();
    UStbMintingContract.grantRole(gatekeeperRole, bob);
    vm.stopPrank();
    assertTrue(UStbMintingContract.hasRole(adminRole, newOwner));
    assertTrue(UStbMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testOldOwnerCantPerformOwnerActions() public {
    vm.prank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    UStbMintingContract.acceptAdmin();
    assertTrue(UStbMintingContract.hasRole(adminRole, newOwner));
    assertFalse(UStbMintingContract.hasRole(adminRole, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UStbMintingContract.grantRole(gatekeeperRole, bob);
    assertFalse(UStbMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testOldOwnerCantTransferOwnership() public {
    vm.prank(owner);
    UStbMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    UStbMintingContract.acceptAdmin();
    assertTrue(UStbMintingContract.hasRole(adminRole, newOwner));
    assertFalse(UStbMintingContract.hasRole(adminRole, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UStbMintingContract.transferAdmin(bob);
    assertFalse(UStbMintingContract.hasRole(adminRole, bob));
  }

  function testNonAdminCanRenounceRoles() public {
    vm.prank(owner);
    UStbMintingContract.grantRole(gatekeeperRole, bob);
    assertTrue(UStbMintingContract.hasRole(gatekeeperRole, bob));

    vm.prank(bob);
    UStbMintingContract.renounceRole(gatekeeperRole, bob);
    assertFalse(UStbMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testCorrectInitConfig() public {
    UStbMinting ustbMinting2 =
      new UStbMinting(assets, tokenConfig, globalConfig, custodians, randomer);
    
    assertFalse(ustbMinting2.hasRole(adminRole, owner));
    assertNotEq(ustbMinting2.owner(), owner);
    assertTrue(ustbMinting2.hasRole(adminRole, randomer));
    assertEq(ustbMinting2.owner(), randomer);
  }

  function testInitConfigBlockLimitMismatch() public {
    // define zero token tokenConfig
    IUStbMinting.TokenConfig[] memory zeroTokenConfig = new IUStbMinting.TokenConfig[](6);
    // 6 zero configs
    for (uint256 i = 0; i < 6; i++) {
      zeroTokenConfig[i] = IUStbMinting.TokenConfig(IUStbMinting.TokenType.ASSET, true, 0, 0);
    }
    vm.expectRevert(InvalidAmount);
    new UStbMinting(assets, zeroTokenConfig, globalConfig, custodians, randomer);

    // mismatched redeem configuration versus assets
    IUStbMinting.TokenConfig[] memory invalidRedeemTokenConfig = new IUStbMinting.TokenConfig[](1);
    invalidRedeemTokenConfig[0] = IUStbMinting.TokenConfig(IUStbMinting.TokenType.ASSET, true, 1, 1);

    vm.expectRevert(InvalidAssetAddress);
    new UStbMinting(
      assets, invalidRedeemTokenConfig, globalConfig, custodians, randomer
    );

    // correct config
    new UStbMinting(assets, tokenConfig, globalConfig, custodians, randomer);
  }
}
