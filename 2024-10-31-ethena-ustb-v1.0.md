**Lead Auditors**

[Immeas](https://twitter.com/0ximmeas)

**Assisting Auditors**



---

# Findings
## Low Risk


### Lack of storage gap in upgradeable base contract

**Description:** To manage access control, Ethena uses a modified version of the OpenZeppelin AccessControl library called `SingleAdminAccessControl`. Since `UStb` is upgradeable, this library has been further modified to function as an upgradeable base contract: [SingleAdminAccessControlUpgradeable](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/SingleAdminAccessControlUpgradeable.sol).

However, it lacks a storage gap at the end. Storage gaps are beneficial because they allow the base contract to add storage variables in the future without "shifting down" all state variables in the inheritance chain.

**Impact:** Upgrading may introduce storage collisions for inheriting contracts.

**Recommended Mitigation:** Consider adding a storage gap at the end:
```solidity
uint256[48] private __gap
```


### `UStb` cannot be burnt when whitelist is enabled

**Description:** The new Ethena `UStb` token has [three](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/IUStbDefinitions.sol#L5-L9) transfer states, one of which is `WHITELIST_ENABLED`. In the `WHITELIST_ENABLED` state, only whitelisted users should be able to send and receive `UStb`. This is enforced through a [check](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L158-L160) in the overridden [`_beforeTokenTransfer`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L147-L168) method to ensure that the `to` address is whitelisted:
```solidity
if (!hasRole(WHITELISTED_ROLE, msg.sender) || !hasRole(WHITELISTED_ROLE, to) || hasRole(BLACKLISTED_ROLE, msg.sender) || hasRole(BLACKLISTED_ROLE, to)){
  revert OperationNotAllowed();
}
```
However, when burning tokens, the `to` address will be [`address(0)`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.9.5/contracts/token/ERC20/ERC20Upgradeable.sol#L285), which will prevent burning.

**Impact:** Whitelisted users will be unable to burn their `UStb` while whitelisting is enabled. This limitation would also prevent them from redeeming their collateral from `UStbMinting`, as that account is whitelisted.

**Proof of Concept:** The following test can be added in `UStb.allTests.t.sol`:
```solidity
function testBurnStateWhitelistEnabledFail() public {
    // transfer state whitelist only, bob is whitelisted
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();

    // bob cannot burn his tokens
    vm.prank(bob);
    vm.expectRevert();
    UStbContract.burn(_transferAmount);
}
```

**Recommended Mitigation:** Consider adding a check for `to != address(0)` in the whitelist verification, or add `address(0)` as a whitelisted address. However, if `address(0)` is added as whitelisted, it would allow a whitelisted operator to burn tokens on behalf of a non-whitelisted user.

**Ethena:** Fixed in [PR#10](https://github.com/ethena-labs/ethena-ustb-audit/pull/10)

**Cyfrin:** Verified. Whitelisted users can burn during whitelist only, both directly and though redeem.


### Non-whitelisted users can transfer `UStb` via whitelisted intermediaries in `WHITELIST_ENABLED` mode


**Description:** When transfers are limited to the `WHITELIST_ENABLED` state, only whitelisted users should be able to send and receive `UStb`, as detailed in the [`AUDIT.md`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/AUDIT.md):

> - **WHITELIST_ENABLED**: Only whitelisted addresses can send and receive this token.

This restriction is enforced in [`_beforeTokenTransfer`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L147-L168) through a [check](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L158-L160):

```solidity
if (!hasRole(WHITELISTED_ROLE, msg.sender) || !hasRole(WHITELISTED_ROLE, to) || hasRole(BLACKLISTED_ROLE, msg.sender) || hasRole(BLACKLISTED_ROLE, to)){
  revert OperationNotAllowed();
}
```

However, a non-whitelisted user can bypass this restriction by approving a whitelisted user to transfer on their behalf. Since only `msg.sender` and `to` are checked, the `from` address can be any non-blacklisted user.

**Impact:** This behavior violates the requirement stated in `AUDIT.md`. Consequently, a non-whitelisted address can still send `UStb`, albeit only to a whitelisted receiver. Additionally, it enables non-whitelisted users to redeem through `UStbMinting`, as the `UStbMinting` contract is a [whitelisted](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L52) address.

**Proof of Concept:** The following test can be added to `UStb.allTest.t.sol`:
```solidity
function testWhitelistedOperatorCanTransferNonWhitelistedTokens() public {
    // transfer state whitelist only, bob is whitelisted
    vm.startPrank(newOwner);
    UStbContract.updateTransferState(IUStbDefinitions.TransferState.WHITELIST_ENABLED);
    UStbContract.grantRole(WHITELISTED_ROLE, bob);
    vm.stopPrank();

    // non-whitelisted user approves whitelisted operator
    vm.prank(greg);
    UStbContract.approve(bob, _transferAmount);

    // whitelisted operator can transfer non-whitelisted user's tokens
    vm.prank(bob);
    UStbContract.transferFrom(greg, bob, _transferAmount);
}
```

**Recommended Mitigation:** Consider verifying that the `from` address is also whitelisted, similar to how blacklisted addresses are handled in the `FULLY_ENABLED` state.

**Ethena:** Fixed in [PR#10](https://github.com/ethena-labs/ethena-ustb-audit/pull/10)

**Cyfrin:** Verified. `from` is not required to have role `WHITELISTED_ROLE`

\clearpage
## Informational


### Unused empty `foundry.toml` file in `contracts/foundry/`

**Description:** In the project root, there is a folder named `/foundry` that contains only an empty file, [`foundry.toml`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/forge/foundry.toml). Consider removing this folder if it is unused.


### Typos and formatting discrepancies

**Description:** The following typos where found in the code comments:

- [`h2olds`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStbMinting.sol#L60) -> `holds`
-  [`enabeld`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/test/foundry/UStb.allTests.t.sol#L241) -> `enabled`
- [`SingleAdminAccessControl`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/SingleAdminAccessControlUpgradeable.sol#L9-L10) -> `SingleAdminAccessControlUpgradeable`

Also a minor formatting discrepancy:
 - Lack of space between closing parenthesis and opening curly bracket [here](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L150) and [here](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStb.sol#L158).



### Lack of event emitted on state change

**Description:** `UStbMinting` includes a safeguard (`stablesDeltaLimit`) to manage stablecoin value fluctuations. The `DEFAULT_ADMIN_ROLE` can adjust this limit via the [`setStablesDeltaLimit`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/UStbMinting.sol#L651-L654) function, shown here:
```solidity
function setStablesDeltaLimit(uint128 _stablesDeltaLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
  stablesDeltaLimit = _stablesDeltaLimit
}
```
However, this function does not emit an event. Given that recent changes to the deployed [EthenaMinting](https://etherscan.io/address/0xe3490297a08d6fC8Da46Edb7B6142E4F461b62D3) contract added events for `setGlobalMaxMintPerBlock`, `setGlobalMaxRedeemPerBlock`, and `disableMintRedeem`, we recommend adding an event in `setStablesDeltaLimit` as well."


### Unused events and errors

**Description:** The following events and errors in [`IUStbDefinitions.sol`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/IUStbDefinitions.sol) are unusused:

- [`event MinterAdded`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/IUStbDefinitions.sol#L11)
- [`event MinterRemoved`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/IUStbDefinitions.sol#L13)
- [`event ToggleTransfers`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/IUStbDefinitions.sol#L17)
- [`error CantRenounceOwnership`](https://github.com/ethena-labs/ethena-ustb-audit/blob/d82676fa43cecab2832cc4804d029b4a07df408f/contracts/contracts/ustb/IUStbDefinitions.sol#L25) (only used in test)

Consider using or removing them.

\clearpage