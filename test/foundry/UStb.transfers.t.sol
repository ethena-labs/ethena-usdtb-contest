// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

/* solhint-disable private-vars-leading-underscore  */
/* solhint-disable func-name-mixedcase  */
/* solhint-disable var-name-mixedcase  */

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "../utils/SigUtils.sol";

import "../../contracts/ustb/UStb.sol";
import "../../contracts/ustb/IUStbDefinitions.sol";
import {UStbBaseSetup} from "./UStbBaseSetup.sol";

contract UStbTransferTest is UStbBaseSetup {
  function test_sender_bl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_bl_to_fully_enabled_revert() public {
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_to_fully_disabled_revert() public {
    vm.prank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_to_fully_enabled_success() public {
    vm.prank(bob);
    UStbContract.transfer(greg, _transferAmount);
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_sender_wl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.prank(alice);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_sender_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    UStbContract.transfer(greg, _transferAmount);
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_sender_wl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.prank(alice);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_sender_wl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_bl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_sender_from_burn_fully_enabled_success() public {
    vm.startPrank(bob);
    UStbContract.burn(_transferAmount);
    vm.stopPrank();
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(bob));
  }

  function test_sender_wl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_burn_whitelist_enabled_reverts() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_sender_wl_from_burn_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(bob));
  }

  // --------------------

  function test_bl_sender_bl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_bl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_from_burn_fully_enabled_revert() public {
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_bl_sender_wl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  // --------------------

  function test_wl_sender_bl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_wl_sender_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_wl_to_whitelist_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_wl_to_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function test_wl_sender_wl_from_bl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_bl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_bl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_wl_to_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_wl_to_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_wl_to_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_bl_from_burn_fully_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transferFrom(bob, greg, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_burn_whitelist_enabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_from_burn_fully_enabled_success() public {
    vm.prank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.prank(bob);
    UStbContract.approve(alice, _transferAmount);
    vm.startPrank(alice);
    UStbContract.burnFrom(bob, _transferAmount);
    vm.stopPrank();
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(bob));
  }

  function test_wl_sender_wl_from_burn_fully_disabled_revert() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.burn(_transferAmount);
    vm.stopPrank();
  }

  function test_wl_sender_wl_from_burn_whitelist_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.burn(_transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(bob));
  }

  function test_wl_sender_wl_from_burn_fully_enabled_success() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.burn(_transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(bob));
  }

  // --------------------

  function testTransferStateFullyDisabled() public {
    vm.prank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  //Whitelist transfer enabled only - Fail expected as bob is not whitelisted
  function testTransferStateWhitelistEnabledFail() public {
    vm.prank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  //Whitelist transfer enabled only - Whitelist bob and transfer to non whitelisted. Fail expected
  function testTransferStateWhitelistEnabledFail2() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();
    vm.startPrank(bob);
    vm.expectRevert();
    UStbContract.transfer(greg, _transferAmount);
  }

  function testTransferStateWhitelistEnabledFail3() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.startPrank(bob);
    UStbContract.approve(greg, _transferAmount);
    vm.stopPrank();
    vm.startPrank(greg);
    vm.expectRevert();
    UStbContract.transferFrom(bob, greg, _transferAmount);
  }

  //Whitelist transfer enabled only - Whitelist bob and greg. transfer from bob to greg
  function testTransferStateWhitelistEnabledPass() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.grantRole(WHITELISTED_ROLE, greg);
    vm.stopPrank();
    vm.prank(bob);
    UStbContract.transfer(greg, _transferAmount);
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function testTransferStateFullyEnabledBlacklistedFromExpectRevert() public {
    vm.prank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function testTransferStateFullyEnabledBlacklistedToExpectRevert() public {
    vm.prank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.FULLY_DISABLED);
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, greg);
    vm.startPrank(bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(greg, _transferAmount);
    vm.stopPrank();
  }

  function testRedistributeLockedAmountPass() public {
    uint256 aliceBalance = UStbContract.balanceOf(alice);
    uint256 bobBalance = UStbContract.balanceOf(bob);
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
    uint256 newBobBalance = UStbContract.balanceOf(bob);
    assertEq(aliceBalance + bobBalance, newBobBalance);
  }

  function testRedistributeLockedAmountWhitelistEnabledPass() public {
    vm.prank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    uint256 aliceBalance = UStbContract.balanceOf(alice);
    uint256 bobBalance = UStbContract.balanceOf(bob);
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    UStbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
    uint256 newBobBalance = UStbContract.balanceOf(bob);
    assertEq(aliceBalance + bobBalance, newBobBalance);
  }

  function testRedistributeLockedAmountNotBlacklistedFromFails() public {
    vm.startPrank(newOwner);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
  }

  function testRedistributeLockedAmountBlacklistedToFails() public {
    vm.startPrank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, bob);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
  }

  function testRedistributeLockedAmountNonAdmin() public {
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.startPrank(bob);
    vm.expectRevert();
    UStbContract.redistributeLockedAmount(alice, bob);
    vm.stopPrank();
  }

  function testRescueTokenAdmin() public {
    vm.prank(alice);
    UStbContract.transfer(address(UStbContract), _transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(alice));
    vm.prank(newOwner);
    UStbContract.rescueTokens(address(UStbContract), _transferAmount, greg);
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(greg));
  }

  function testRescueTokenNonAdmin() public {
    vm.prank(alice);
    UStbContract.transfer(address(UStbContract), _transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(alice));
    vm.startPrank(bob);
    vm.expectRevert();
    UStbContract.rescueTokens(address(UStbContract), _transferAmount, greg);
  }
}
