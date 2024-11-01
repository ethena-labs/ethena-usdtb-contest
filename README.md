# UStb token and minting

Contracts in scope:

1) `contracts/SingleAdminAccessControl.sol`
2) `contracts/SingleAdminAccessControlUpgradeable.sol`
3) `contracts/ustb/UStb.sol`
4) `contracts/ustb/UStbMinting.sol`

## UStb token features

**Overview**: An upgradeable ERC20 with mint and burn functionality and various transfer states that is controlled by a single admin address.

#### 1. Whitelisting

A set of addresses that are whitelisted for the purpose of transfer restrictions. Only the whitelist manager specified by the admin can add or remove whitelist addresses.

#### 2. Blacklisting

A set of addresses that are blacklisted for the purpose of transfer restrictions. In any case blacklisted addresses cannot send or receive tokens, apart from burning their tokens. Only the blacklist manager specified by the admin can add or remove blacklisted addresses.

#### 3. Token Redistribution

Allows the admin to forcefully move tokens from a blacklisted address to a non-blacklisted address.

#### 4. Transfer States

The admin address can change the state at any time, without a timelock. There are three main transfer states to consider:

- **FULLY_DISABLED**: No holder of this token, whether whitelisted, blacklisted or otherwise can send or receive this token.
- **WHITELIST_ENABLED**: Only whitelisted addresses can send and receive this token.
- **FULLY_ENABLED**: Only non-blacklisted addresses can send and receive this token.

## UStb minting features

**Overview**: A contract defining the operations to mint and redeem UStb tokens based on signed orders that is controlled by a single admin. The price present in any mint/redeem orders are determined by an off-chain RFQ system controlled by Ethena, which a benefactor may accept and sign an order for. The minter/redeemer then has last look rights to be able to filter out any malicious orders and proceed with on-chain settlement.

#### 1. Max mint/redeem per block by collateral

Implements the max amount of UStb that can be minted/redeemed in a single block using a certain type of collateral. The limit can be adjusted by the admin on a per collateral basis, regardless whether the collateral is active or not.

#### 2. Global max mint/redeem per block

In addition to mint/redeem limits by collateral, there is a global mint/redeem per block configuration that caps the amount of UStb that can be minted in a single block, regardless of the collateral used to mint UStb. The admin can adjust this configurations, regardless whether the collateral is active or not.

#### 3. Delegate signer

Allows an address to delegate signing to another address. The mechanism to set a delegate signer is a two-step process, first the delegator needs to propose a delegatee, finally the delegatee needs to accept the role. The purpose of this feature is to allow smart contracts to delegate signing to an EOA to sign mint/redeem instructions.

#### 4. Custodians

Custodians are the only addresses that can receive collateral assets from the mint process.

#### 5. Benefactor

An address holding collateral assets (benefactor) for a minting instruction that can receive UStb from the minting process. Benefactors are entities that have undergone KYC with Ethena and have been expressly registered by the admin to be able to participate in mint/redeem operations.

#### 6. Beneficiary

An address holding collateral assets (benefactor) for a minting instruction can assign a different address (beneficiary) to receive UStb.
