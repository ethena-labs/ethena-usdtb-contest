// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../USDtbMinting.utils.sol";
import "../../../contracts/usdtb/IUSDtbMinting.sol";
import "../../../contracts/interfaces/ISingleAdminAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../contracts/usdtb/IUSDtbMinting.sol";

contract USDtbMintingACLTest is USDtbMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_redeem_notRedeemer_revert() public {
    (IUSDtbMinting.Order memory redeemOrder, IUSDtbMinting.Signature memory takerSignature2) =
      redeem_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.startPrank(minter);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(minter), " is missing role ", vm.toString(redeemerRole)
        )
      )
    );
    USDtbMintingContract.redeem(redeemOrder, takerSignature2);
  }

  function test_fuzz_notMinter_cannot_mint(address nonMinter) public {
    (
      IUSDtbMinting.Order memory mintOrder,
      IUSDtbMinting.Signature memory takerSignature,
      IUSDtbMinting.Route memory route
    ) = mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.assume(nonMinter != minter);
    vm.startPrank(nonMinter);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(nonMinter), " is missing role ", vm.toString(minterRole)
        )
      )
    );
    USDtbMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usdtbToken.balanceOf(beneficiary), 0);
  }

  function test_fuzz_nonOwner_cannot_add_supportedAsset_revert(address nonOwner) public {
    vm.assume(nonOwner != owner);
    address asset = address(20);
    vm.expectRevert();
    vm.prank(nonOwner);
    IUSDtbMinting.TokenConfig memory tokenConfig = IUSDtbMinting.TokenConfig(
      IUSDtbMinting.TokenType.ASSET, true, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK
    );
    USDtbMintingContract.addSupportedAsset(asset, tokenConfig);
    assertFalse(USDtbMintingContract.isSupportedAsset(asset));
  }

  function test_fuzz_nonOwner_cannot_remove_supportedAsset_revert(address nonOwner) public {
    vm.assume(nonOwner != owner);
    address asset = address(20);
    vm.prank(owner);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    IUSDtbMinting.TokenConfig memory tokenConfig = IUSDtbMinting.TokenConfig(
      IUSDtbMinting.TokenType.ASSET, true, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK, MAX_USDE_MINT_AND_REDEEM_PER_BLOCK
    );
    USDtbMintingContract.addSupportedAsset(asset, tokenConfig);
    assertTrue(USDtbMintingContract.isSupportedAsset(asset));

    vm.expectRevert();
    vm.prank(nonOwner);
    USDtbMintingContract.removeSupportedAsset(asset);
    assertTrue(USDtbMintingContract.isSupportedAsset(asset));
  }

  function test_collateralManager_canTransfer_custody() public {
    vm.startPrank(owner);
    stETHToken.mint(1000, address(USDtbMintingContract));
    USDtbMintingContract.addCustodianAddress(beneficiary);
    USDtbMintingContract.grantRole(collateralManagerRole, minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectEmit(true, true, true, true);
    emit CustodyTransfer(beneficiary, address(stETHToken), 1000);
    USDtbMintingContract.transferToCustody(beneficiary, address(stETHToken), 1000);
    assertEq(stETHToken.balanceOf(beneficiary), 1000);
    assertEq(stETHToken.balanceOf(address(USDtbMintingContract)), 0);
  }

  function test_collateralManager_canTransferNative_custody() public {
    vm.startPrank(owner);
    vm.deal(address(USDtbMintingContract), 1000);
    USDtbMintingContract.addCustodianAddress(beneficiary);
    USDtbMintingContract.grantRole(collateralManagerRole, minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectEmit(true, true, true, true);
    emit CustodyTransfer(beneficiary, address(NATIVE_TOKEN), 1000);
    USDtbMintingContract.transferToCustody(beneficiary, address(NATIVE_TOKEN), 1000);
    assertEq(beneficiary.balance, 1000);
    assertEq(address(USDtbMintingContract).balance, 0);
  }

  function test_collateralManager_cannotTransfer_zeroAddress() public {
    vm.startPrank(owner);
    stETHToken.mint(1000, address(USDtbMintingContract));
    USDtbMintingContract.addCustodianAddress(beneficiary);
    USDtbMintingContract.grantRole(collateralManagerRole, minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectRevert(IUSDtbMinting.InvalidAddress.selector);
    USDtbMintingContract.transferToCustody(address(0), address(stETHToken), 1000);
  }

  function test_fuzz_nonCollateralManager_cannot_transferCustody_revert(address nonCollateralManager) public {
    vm.assume(
      nonCollateralManager != collateralManager && nonCollateralManager != owner && nonCollateralManager != address(0)
    );
    stETHToken.mint(1000, address(USDtbMintingContract));

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
    USDtbMintingContract.transferToCustody(beneficiary, address(stETHToken), 1000);
  }

  /**
   * Gatekeeper tests
   */
  function test_gatekeeper_can_remove_minter() public {
    vm.prank(gatekeeper);

    USDtbMintingContract.removeMinterRole(minter);
    assertFalse(USDtbMintingContract.hasRole(minterRole, minter));
  }

  function test_gatekeeper_can_remove_redeemer() public {
    vm.prank(gatekeeper);

    USDtbMintingContract.removeRedeemerRole(redeemer);
    assertFalse(USDtbMintingContract.hasRole(redeemerRole, redeemer));
  }

  function test_gatekeeper_can_remove_collateral_manager() public {
    vm.prank(gatekeeper);

    USDtbMintingContract.removeCollateralManagerRole(collateralManager);
    assertFalse(USDtbMintingContract.hasRole(collateralManagerRole, collateralManager));
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
    USDtbMintingContract.removeMinterRole(minter);
    assertTrue(USDtbMintingContract.hasRole(minterRole, minter));
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
    USDtbMintingContract.removeRedeemerRole(redeemer);
    assertTrue(USDtbMintingContract.hasRole(redeemerRole, redeemer));
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
    USDtbMintingContract.removeCollateralManagerRole(collateralManager);
    assertTrue(USDtbMintingContract.hasRole(collateralManagerRole, collateralManager));
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
    USDtbMintingContract.grantRole(minterRole, bob);
    assertFalse(USDtbMintingContract.hasRole(minterRole, bob), "Bob should lack the minter role");
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
    USDtbMintingContract.grantRole(collateralManagerRole, bob);
    assertFalse(USDtbMintingContract.hasRole(collateralManagerRole, bob), "Bob should lack the collateralManager role");
  }

  function test_gatekeeper_can_disable_mintRedeem() public {
    vm.startPrank(gatekeeper);
    USDtbMintingContract.disableMintRedeem();

    (IUSDtbMinting.Order memory order, IUSDtbMinting.Signature memory takerSignature, IUSDtbMinting.Route memory route)
    = mint_setup(_usdtbToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    vm.expectRevert(GlobalMaxMintPerBlockExceeded);
    USDtbMintingContract.mint(order, route, takerSignature);

    vm.prank(redeemer);
    vm.expectRevert(GlobalMaxRedeemPerBlockExceeded);
    USDtbMintingContract.redeem(order, takerSignature);

    (uint128 globalMaxMintPerBlock, uint128 globalMaxRedeemPerBlock) = USDtbMintingContract.globalConfig();

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
    USDtbMintingContract.disableMintRedeem();

    assertTrue(tokenConfig[0].maxMintPerBlock > 0);
    assertTrue(tokenConfig[0].maxRedeemPerBlock > 0);
  }

  /**
   * Admin tests
   */
  function test_admin_can_disable_mint(bool performCheckMint) public {
    vm.prank(owner);
    USDtbMintingContract.setMaxMintPerBlock(0, address(stETHToken));

    if (performCheckMint) maxMint_perBlock_exceeded_revert(1e18);

    (,, uint128 maxMintPerBlock,) = USDtbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxMintPerBlock, 0, "The minting should be disabled");
  }

  function test_admin_can_disable_redeem(bool performCheckRedeem) public {
    vm.prank(owner);
    USDtbMintingContract.setMaxRedeemPerBlock(0, address(stETHToken));

    if (performCheckRedeem) maxRedeem_perBlock_exceeded_revert(1e18);

    (,,, uint128 maxRedeemPerBlock) = USDtbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock, 0, "The redeem should be disabled");
  }

  function test_admin_can_enable_mint() public {
    vm.startPrank(owner);
    USDtbMintingContract.setMaxMintPerBlock(0, address(stETHToken));

    (,, uint128 maxMintPerBlock1,) = USDtbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxMintPerBlock1, 0, "The minting should be disabled");

    // Re-enable the minting
    USDtbMintingContract.setMaxMintPerBlock(_maxMintPerBlock, address(stETHToken));

    vm.stopPrank();

    executeMint(stETHToken);

    (,, uint128 maxMintPerBlock2,) = USDtbMintingContract.tokenConfig(address(stETHToken));

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
    USDtbMintingContract.setMaxMintPerBlock(_maxMintPerBlock, address(stETHToken));

    maxMint_perBlock_exceeded_revert(1e18);

    (,, uint128 maxMintPerBlock,) = USDtbMintingContract.tokenConfig(address(stETHToken));

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
    USDtbMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock, address(stETHToken));

    maxRedeem_perBlock_exceeded_revert(1e18);

    (,,, uint128 maxRedeemPerBlock) = USDtbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock, 0, "The redeeming should remain disabled");
  }

  function test_admin_can_enable_redeem() public {
    vm.startPrank(owner);
    USDtbMintingContract.setMaxRedeemPerBlock(0, address(stETHToken));

    (,,, uint128 maxRedeemPerBlock1) = USDtbMintingContract.tokenConfig(address(stETHToken));

    assertEq(maxRedeemPerBlock1, 0, "The redeem should be disabled");

    // Re-enable the redeeming
    USDtbMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock, address(stETHToken));

    vm.stopPrank();

    executeRedeem(stETHToken);

    (,,, uint128 maxRedeemPerBlock2) = USDtbMintingContract.tokenConfig(address(stETHToken));

    assertTrue(maxRedeemPerBlock2 > 0, "The redeeming should be enabled");
  }

  function test_admin_can_add_minter() public {
    vm.startPrank(owner);
    USDtbMintingContract.grantRole(minterRole, bob);

    assertTrue(USDtbMintingContract.hasRole(minterRole, bob), "Bob should have the minter role");
    vm.stopPrank();
  }

  function test_admin_can_remove_minter() public {
    test_admin_can_add_minter();

    vm.startPrank(owner);
    USDtbMintingContract.revokeRole(minterRole, bob);

    assertFalse(USDtbMintingContract.hasRole(minterRole, bob), "Bob should no longer have the minter role");

    vm.stopPrank();
  }

  function test_admin_can_add_gatekeeper() public {
    vm.startPrank(owner);
    USDtbMintingContract.grantRole(gatekeeperRole, bob);

    assertTrue(USDtbMintingContract.hasRole(gatekeeperRole, bob), "Bob should have the gatekeeper role");
    vm.stopPrank();
  }

  function test_admin_can_remove_gatekeeper() public {
    test_admin_can_add_gatekeeper();

    vm.startPrank(owner);
    USDtbMintingContract.revokeRole(gatekeeperRole, bob);

    assertFalse(USDtbMintingContract.hasRole(gatekeeperRole, bob), "Bob should no longer have the gatekeeper role");

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
    USDtbMintingContract.revokeRole(minterRole, bob);

    assertTrue(USDtbMintingContract.hasRole(minterRole, bob), "Bob should maintain the minter role");
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
    USDtbMintingContract.revokeRole(gatekeeperRole, bob);

    assertTrue(USDtbMintingContract.hasRole(gatekeeperRole, bob), "Bob should maintain the gatekeeper role");

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
    USDtbMintingContract.grantRole(minterRole, bob);

    assertFalse(USDtbMintingContract.hasRole(minterRole, bob), "Bob should lack the minter role");
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
    USDtbMintingContract.grantRole(gatekeeperRole, bob);

    assertFalse(USDtbMintingContract.hasRole(gatekeeperRole, bob), "Bob should lack the gatekeeper role");

    vm.stopPrank();
  }

  function test_base_transferAdmin() public {
    vm.prank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    assertTrue(USDtbMintingContract.hasRole(adminRole, owner));
    assertFalse(USDtbMintingContract.hasRole(adminRole, newOwner));

    vm.prank(newOwner);
    USDtbMintingContract.acceptAdmin();
    assertFalse(USDtbMintingContract.hasRole(adminRole, owner));
    assertTrue(USDtbMintingContract.hasRole(adminRole, newOwner));
  }

  function test_transferAdmin_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert();
    USDtbMintingContract.transferAdmin(randomer);
  }

  function test_grantRole_AdminRoleExternally() public {
    vm.startPrank(randomer);
    vm.expectRevert(
      "AccessControl: account 0xc91041eae7bf78e1040f4abd7b29908651f45546 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    USDtbMintingContract.grantRole(adminRole, randomer);
    vm.stopPrank();
  }

  function test_revokeRole_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert(
      "AccessControl: account 0xc91041eae7bf78e1040f4abd7b29908651f45546 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    USDtbMintingContract.revokeRole(adminRole, owner);
  }

  function test_revokeRole_AdminRole() public {
    vm.startPrank(owner);
    vm.expectRevert();
    USDtbMintingContract.revokeRole(adminRole, owner);
  }

  function test_renounceRole_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert(InvalidAdminChange);
    USDtbMintingContract.renounceRole(adminRole, owner);
  }

  function test_renounceRole_AdminRole() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAdminChange);
    USDtbMintingContract.renounceRole(adminRole, owner);
  }

  function test_revoke_AdminRole() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAdminChange);
    USDtbMintingContract.revokeRole(adminRole, owner);
  }

  function test_grantRole_nonAdminRole() public {
    vm.prank(owner);
    USDtbMintingContract.grantRole(minterRole, randomer);
    assertTrue(USDtbMintingContract.hasRole(minterRole, randomer));
  }

  function test_revokeRole_nonAdminRole() public {
    vm.startPrank(owner);
    USDtbMintingContract.grantRole(minterRole, randomer);
    USDtbMintingContract.revokeRole(minterRole, randomer);
    vm.stopPrank();
    assertFalse(USDtbMintingContract.hasRole(minterRole, randomer));
  }

  function test_renounceRole_nonAdminRole() public {
    vm.prank(owner);
    USDtbMintingContract.grantRole(minterRole, randomer);
    vm.prank(randomer);
    USDtbMintingContract.renounceRole(minterRole, randomer);
    assertFalse(USDtbMintingContract.hasRole(minterRole, randomer));
  }

  function testCanRepeatedlyTransferAdmin() public {
    vm.startPrank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    USDtbMintingContract.transferAdmin(randomer);
    vm.stopPrank();
  }

  function test_renounceRole_forDifferentAccount() public {
    vm.prank(randomer);
    vm.expectRevert("AccessControl: can only renounce roles for self");
    USDtbMintingContract.renounceRole(minterRole, owner);
  }

  function testCancelTransferAdmin() public {
    vm.startPrank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    USDtbMintingContract.transferAdmin(address(0));
    vm.stopPrank();
    assertTrue(USDtbMintingContract.hasRole(adminRole, owner));
    assertFalse(USDtbMintingContract.hasRole(adminRole, address(0)));
    assertFalse(USDtbMintingContract.hasRole(adminRole, newOwner));
  }

  function test_admin_cannot_transfer_self() public {
    vm.startPrank(owner);
    vm.expectRevert(InvalidAdminChange);
    USDtbMintingContract.transferAdmin(owner);
    vm.stopPrank();
    assertTrue(USDtbMintingContract.hasRole(adminRole, owner));
  }

  function testAdminCanCancelTransfer() public {
    vm.startPrank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    USDtbMintingContract.transferAdmin(address(0));
    vm.stopPrank();

    vm.prank(newOwner);
    vm.expectRevert(ISingleAdminAccessControl.NotPendingAdmin.selector);
    USDtbMintingContract.acceptAdmin();

    assertTrue(USDtbMintingContract.hasRole(adminRole, owner));
    assertFalse(USDtbMintingContract.hasRole(adminRole, address(0)));
    assertFalse(USDtbMintingContract.hasRole(adminRole, newOwner));
  }

  function testOwnershipCannotBeRenounced() public {
    vm.startPrank(owner);
    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    USDtbMintingContract.renounceRole(adminRole, owner);

    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    USDtbMintingContract.revokeRole(adminRole, owner);
    vm.stopPrank();
    assertEq(USDtbMintingContract.owner(), owner);
    assertTrue(USDtbMintingContract.hasRole(adminRole, owner));
  }

  function testOwnershipTransferRequiresTwoSteps() public {
    vm.prank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    assertEq(USDtbMintingContract.owner(), owner);
    assertTrue(USDtbMintingContract.hasRole(adminRole, owner));
    assertNotEq(USDtbMintingContract.owner(), newOwner);
    assertFalse(USDtbMintingContract.hasRole(adminRole, newOwner));
  }

  function testCanTransferOwnership() public {
    vm.prank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    USDtbMintingContract.acceptAdmin();
    assertTrue(USDtbMintingContract.hasRole(adminRole, newOwner));
    assertFalse(USDtbMintingContract.hasRole(adminRole, owner));
  }

  function testNewOwnerCanPerformOwnerActions() public {
    vm.prank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    vm.startPrank(newOwner);
    USDtbMintingContract.acceptAdmin();
    USDtbMintingContract.grantRole(gatekeeperRole, bob);
    vm.stopPrank();
    assertTrue(USDtbMintingContract.hasRole(adminRole, newOwner));
    assertTrue(USDtbMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testOldOwnerCantPerformOwnerActions() public {
    vm.prank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    USDtbMintingContract.acceptAdmin();
    assertTrue(USDtbMintingContract.hasRole(adminRole, newOwner));
    assertFalse(USDtbMintingContract.hasRole(adminRole, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    USDtbMintingContract.grantRole(gatekeeperRole, bob);
    assertFalse(USDtbMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testOldOwnerCantTransferOwnership() public {
    vm.prank(owner);
    USDtbMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    USDtbMintingContract.acceptAdmin();
    assertTrue(USDtbMintingContract.hasRole(adminRole, newOwner));
    assertFalse(USDtbMintingContract.hasRole(adminRole, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    USDtbMintingContract.transferAdmin(bob);
    assertFalse(USDtbMintingContract.hasRole(adminRole, bob));
  }

  function testNonAdminCanRenounceRoles() public {
    vm.prank(owner);
    USDtbMintingContract.grantRole(gatekeeperRole, bob);
    assertTrue(USDtbMintingContract.hasRole(gatekeeperRole, bob));

    vm.prank(bob);
    USDtbMintingContract.renounceRole(gatekeeperRole, bob);
    assertFalse(USDtbMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testCorrectInitConfig() public {
    USDtbMinting usdtbMinting2 = new USDtbMinting(assets, tokenConfig, globalConfig, custodians, randomer);

    assertFalse(usdtbMinting2.hasRole(adminRole, owner));
    assertNotEq(usdtbMinting2.owner(), owner);
    assertTrue(usdtbMinting2.hasRole(adminRole, randomer));
    assertEq(usdtbMinting2.owner(), randomer);
  }

  function testInitConfigBlockLimitMismatch() public {
    // define zero token tokenConfig
    IUSDtbMinting.TokenConfig[] memory zeroTokenConfig = new IUSDtbMinting.TokenConfig[](6);
    // 6 zero configs
    for (uint256 i = 0; i < 6; i++) {
      zeroTokenConfig[i] = IUSDtbMinting.TokenConfig(IUSDtbMinting.TokenType.ASSET, true, 0, 0);
    }
    vm.expectRevert(InvalidAmount);
    new USDtbMinting(assets, zeroTokenConfig, globalConfig, custodians, randomer);

    // mismatched redeem configuration versus assets
    IUSDtbMinting.TokenConfig[] memory invalidRedeemTokenConfig = new IUSDtbMinting.TokenConfig[](1);
    invalidRedeemTokenConfig[0] = IUSDtbMinting.TokenConfig(IUSDtbMinting.TokenType.ASSET, true, 1, 1);

    vm.expectRevert(InvalidAssetAddress);
    new USDtbMinting(assets, invalidRedeemTokenConfig, globalConfig, custodians, randomer);

    // correct config
    new USDtbMinting(assets, tokenConfig, globalConfig, custodians, randomer);
  }
}
