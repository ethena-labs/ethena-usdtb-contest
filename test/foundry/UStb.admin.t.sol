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

contract UStbTest is UStbBaseSetup {
  function testRandomAddressGrantRevokeBlackistWhitelistRoleException() public {
    vm.startPrank(alice);
    vm.expectRevert();
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.expectRevert();
    UStbContract.revokeRole(BLACKLISTED_ROLE, alice);
    vm.expectRevert();
    UStbContract.addBlacklistAddress(new address[](0));
    vm.expectRevert();
    UStbContract.removeBlacklistAddress(new address[](0));
    vm.expectRevert();
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.expectRevert();
    UStbContract.revokeRole(WHITELISTED_ROLE, alice);
    vm.expectRevert();
    UStbContract.addWhitelistAddress(new address[](0));
    vm.expectRevert();
    UStbContract.removeWhitelistAddress(new address[](0));
    vm.stopPrank();
  }

  function testAdminCanGrantRevokeBlacklistRole() public {
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLISTED_ROLE, alice);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    // alice cannot receive tokens
    vm.startPrank(greg);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(alice, _transferAmount);
    vm.stopPrank();

    assertEq(_amount, UStbContract.balanceOf(alice));

    vm.prank(newOwner);
    UStbContract.revokeRole(BLACKLISTED_ROLE, alice);

    vm.prank(alice);
    UStbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(alice));
  }

  function testBlacklistManagerCanGrantRevokeBlacklistRole() public {
    vm.prank(newOwner);
    UStbContract.grantRole(BLACKLIST_MANAGER_ROLE, newOwner);

    address[] memory toBlacklist = new address[](1);
    toBlacklist[0] = alice;
    vm.prank(newOwner);
    UStbContract.addBlacklistAddress(toBlacklist);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    // alice cannot receive tokens
    vm.startPrank(greg);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(alice, _transferAmount);
    vm.stopPrank();

    assertEq(_amount, UStbContract.balanceOf(alice));

    vm.prank(newOwner);
    UStbContract.removeBlacklistAddress(toBlacklist);

    vm.prank(alice);
    UStbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(alice));
  }

  function testAdminCanGrantRevokeWhitelistRole() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, alice);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();

    // alice can send tokens, bob can receive tokens
    assertEq(_amount, UStbContract.balanceOf(alice));
    vm.prank(alice);
    UStbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(alice));
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(bob));

    vm.prank(newOwner);
    UStbContract.revokeRole(WHITELISTED_ROLE, bob);

    // bob cannot receive tokens
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    vm.prank(newOwner);
    UStbContract.revokeRole(WHITELISTED_ROLE, alice);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();
  }

  function testWhitelistManagerCanGrantRevokeWhitelistRole() public {
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELIST_MANAGER_ROLE, newOwner);
    address[] memory toWhitelist = new address[](2);
    toWhitelist[0] = alice;
    toWhitelist[1] = bob;
    UStbContract.addWhitelistAddress(toWhitelist);
    vm.stopPrank();

    // alice can send tokens, bob can receive tokens
    assertEq(_amount, UStbContract.balanceOf(alice));
    vm.prank(alice);
    UStbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, UStbContract.balanceOf(alice));
    assertEq(_amount + _transferAmount, UStbContract.balanceOf(bob));

    address[] memory toRemoveWhitelist = new address[](1);
    toRemoveWhitelist[0] = bob;
    vm.prank(newOwner);
    UStbContract.removeWhitelistAddress(toRemoveWhitelist);

    // bob cannot receive tokens
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    toRemoveWhitelist[0] = alice;
    vm.prank(newOwner);
    UStbContract.removeWhitelistAddress(toRemoveWhitelist);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.transfer(bob, _transferAmount);
    vm.stopPrank();
  }

  function testRenounceRoleExpectRevert() public {
    vm.startPrank(newOwner);
    vm.expectRevert(IUStbDefinitions.OperationNotAllowed.selector);
    UStbContract.renounceRole(WHITELISTED_ROLE, DEAD_ADDRESS);
    vm.stopPrank();
  }

  function testInvalidMinter() public {
    vm.startPrank(bob);
    vm.expectRevert();
    UStbContract.mint(greg, _amount);
    vm.stopPrank();
  }
}
