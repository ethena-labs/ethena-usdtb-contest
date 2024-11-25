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

contract USDtbTest is USDtbBaseSetup {
  function testRandomAddressGrantRevokeBlackistWhitelistRoleException() public {
    vm.startPrank(alice);
    vm.expectRevert();
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);
    vm.expectRevert();
    USDtbContract.revokeRole(BLACKLISTED_ROLE, alice);
    vm.expectRevert();
    USDtbContract.addBlacklistAddress(new address[](0));
    vm.expectRevert();
    USDtbContract.removeBlacklistAddress(new address[](0));
    vm.expectRevert();
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    vm.expectRevert();
    USDtbContract.revokeRole(WHITELISTED_ROLE, alice);
    vm.expectRevert();
    USDtbContract.addWhitelistAddress(new address[](0));
    vm.expectRevert();
    USDtbContract.removeWhitelistAddress(new address[](0));
    vm.stopPrank();
  }

  function testAdminCanGrantRevokeBlacklistRole() public {
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLISTED_ROLE, alice);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    // alice cannot receive tokens
    vm.startPrank(greg);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(alice, _transferAmount);
    vm.stopPrank();

    assertEq(_amount, USDtbContract.balanceOf(alice));

    vm.prank(newOwner);
    USDtbContract.revokeRole(BLACKLISTED_ROLE, alice);

    vm.prank(alice);
    USDtbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(alice));
  }

  function testBlacklistManagerCanGrantRevokeBlacklistRole() public {
    vm.prank(newOwner);
    USDtbContract.grantRole(BLACKLIST_MANAGER_ROLE, newOwner);

    address[] memory toBlacklist = new address[](1);
    toBlacklist[0] = alice;
    vm.prank(newOwner);
    USDtbContract.addBlacklistAddress(toBlacklist);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    // alice cannot receive tokens
    vm.startPrank(greg);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(alice, _transferAmount);
    vm.stopPrank();

    assertEq(_amount, USDtbContract.balanceOf(alice));

    vm.prank(newOwner);
    USDtbContract.removeBlacklistAddress(toBlacklist);

    vm.prank(alice);
    USDtbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(alice));
  }

  function testAdminCanGrantRevokeWhitelistRole() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELISTED_ROLE, alice);
    USDtbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();

    // alice can send tokens, bob can receive tokens
    assertEq(_amount, USDtbContract.balanceOf(alice));
    vm.prank(alice);
    USDtbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(alice));
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(bob));

    vm.prank(newOwner);
    USDtbContract.revokeRole(WHITELISTED_ROLE, bob);

    // bob cannot receive tokens
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    vm.prank(newOwner);
    USDtbContract.revokeRole(WHITELISTED_ROLE, alice);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();
  }

  function testWhitelistManagerCanGrantRevokeWhitelistRole() public {
    vm.startPrank(newOwner);
    USDtbContract.updateTransferState(IUSDtbDefinitions.TransferState.WHITELIST_ENABLED);
    USDtbContract.grantRole(WHITELIST_MANAGER_ROLE, newOwner);
    address[] memory toWhitelist = new address[](2);
    toWhitelist[0] = alice;
    toWhitelist[1] = bob;
    USDtbContract.addWhitelistAddress(toWhitelist);
    vm.stopPrank();

    // alice can send tokens, bob can receive tokens
    assertEq(_amount, USDtbContract.balanceOf(alice));
    vm.prank(alice);
    USDtbContract.transfer(bob, _transferAmount);
    assertEq(_amount - _transferAmount, USDtbContract.balanceOf(alice));
    assertEq(_amount + _transferAmount, USDtbContract.balanceOf(bob));

    address[] memory toRemoveWhitelist = new address[](1);
    toRemoveWhitelist[0] = bob;
    vm.prank(newOwner);
    USDtbContract.removeWhitelistAddress(toRemoveWhitelist);

    // bob cannot receive tokens
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();

    toRemoveWhitelist[0] = alice;
    vm.prank(newOwner);
    USDtbContract.removeWhitelistAddress(toRemoveWhitelist);

    // alice cannot send tokens
    vm.startPrank(alice);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.transfer(bob, _transferAmount);
    vm.stopPrank();
  }

  function testRenounceRoleExpectRevert() public {
    vm.startPrank(newOwner);
    vm.expectRevert(IUSDtbDefinitions.OperationNotAllowed.selector);
    USDtbContract.renounceRole(WHITELISTED_ROLE, DEAD_ADDRESS);
    vm.stopPrank();
  }

  function testInvalidMinter() public {
    vm.startPrank(bob);
    vm.expectRevert();
    USDtbContract.mint(greg, _amount);
    vm.stopPrank();
  }
}
