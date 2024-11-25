// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

/* solhint-disable private-vars-leading-underscore  */
/* solhint-disable func-name-mixedcase  */
/* solhint-disable var-name-mixedcase  */

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "../utils/SigUtils.sol";

import "../../contracts/usdtb/USDtb.sol";
import "../../contracts/usdtb/IUSDtbDefinitions.sol";
import {USDtbBaseSetup} from "./USDtbBaseSetup.sol";

contract USDtbTransferTest is USDtbBaseSetup {
  function test_sender_bl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_bl_to_fully_enabled_revert() public {
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_to_fully_disabled_revert() public {
    vm.prank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_to_fully_enabled_success() public {
    vm.prank(bob);
    USDtbContract.transfer(greg, _transferAmount);
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_sender_wl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.prank(alice);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_sender_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    USDtbContract.transfer(greg, _transferAmount);
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_sender_wl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.prank(alice);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_sender_wl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_burn_fully_enabled_success() public {
    vm.startPrank(bob);
    USDtbContract.burn(_transferAmount);
    vm.stopPrank();
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(bob));
  }

  function test_sender_wl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_burn_whitelist_enabled_reverts() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_burn_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(bob));
  }

  // --------------------

  function test_bl_sender_bl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_burn_fully_enabled_revert() public {
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  // --------------------

  function test_wl_sender_bl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_wl_sender_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_wl_to_whitelist_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_burn_fully_enabled_success() public {
    vm.prank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.prank(bob);
    USDtbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    USDtbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(bob));
  }

  function test_wl_sender_wl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_burn_whitelist_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.burn(_transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(bob));
  }

  function test_wl_sender_wl_from_burn_fully_enabled_success() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.burn(_transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(bob));
  }

  // --------------------

  function testTransferStateFullyDisabled() public {
    vm.prank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  //Whitelist transfer enabled only - Fail expected as bob is not whitelisted
  function testTransferStateWhitelistEnabledFail() public {
    vm.prank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  //Whitelist transfer enabled only - Whitelist bob and transfer to non whitelisted. Fail expected
  function testTransferStateWhitelistEnabledFail2() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert();
    USDtbContract.transfer(greg, _transferAmount);
  }

  function testTransferStateWhitelistEnabledFail3() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    USDtbContract.approve(greg, _transferAmount);
    vm.stopPrank();
    vm.startPrank(greg);
    vm.expectRevert();
    USDtbContract.transferFrom(bob, greg, _transferAmount);
  }

  //Whitelist transfer enabled only - Whitelist bob and greg. transfer from bob to greg
  function testTransferStateWhitelistEnabledPass() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    USDtbContract.transfer(greg, _transferAmount);
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function testTransferStateFullyEnabledBlacklistedFromExpectRevert() public {
    vm.prank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function testTransferStateFullyEnabledBlacklistedToExpectRevert() public {
    vm.prank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.FULLY_DISABLED);
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.startPrank(bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function testRedistributeLockedAmountPass() public {
    uint256 aliceBalance = USDtbContract.balanceOf(alice);
    uint256 bobBalance = USDtbContract.balanceOf(bob);
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
    uint256 newBobBalance = USDtbContract.balanceOf(bob);
    assertEq(aliceBalance + bobBalance, newBobBalance);
  }

  function testRedistributeLockedAmountWhitelistEnabledPass() public {
    vm.prank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    uint256 aliceBalance = USDtbContract.balanceOf(alice);
    uint256 bobBalance = USDtbContract.balanceOf(bob);
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    USDtbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
    uint256 newBobBalance = USDtbContract.balanceOf(bob);
    assertEq(aliceBalance + bobBalance, newBobBalance);
  }

  function testRedistributeLockedAmountNotBlacklistedFromFails() public {
    vm.startPrank(newOwner);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
  }

  function testRedistributeLockedAmountBlacklistedToFails() public {
    vm.startPrank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
  }

  function testRedistributeLockedAmountNonAdmin() public {
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.startPrank(bob);
    vm.expectRevert();
    USDtbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
  }

  function testRescueTokenAdmin() public {
    vm.prank(alice);
    USDtbContract.transfer(address(USDtbContract), _transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(alice));
    vm.prank(newOwner);
    USDtbContract.rescueTokens(address(USDtbContract), _transferAmount, greg);
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(greg));
  }

  function testRescueTokenNonAdmin() public {
    vm.prank(alice);
    USDtbContract.transfer(address(USDtbContract), _transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(alice));
    vm.startPrank(bob);
    vm.expectRevert();
    USDtbContract.rescueTokens(address(USDtbContract), _transferAmount, greg);
  }
}
