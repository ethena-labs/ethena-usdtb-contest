// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* solhint-disable var-name-mixedcase  */

interface IUSDtbMintingEvents {
  /// @notice Event emitted when contract receives ETH
  event Received(address, uint256);

  /// @notice Event emitted when USDtb is minted
  event Mint(
    string indexed order_id,
    address indexed benefactor,
    address indexed beneficiary,
    address minter,
    address collateral_asset,
    uint256 collateral_amount,
    uint256 usdtb_amount
  );

  /// @notice Event emitted when funds are redeemed
  event Redeem(
    string indexed order_id,
    address indexed benefactor,
    address indexed beneficiary,
    address redeemer,
    address collateral_asset,
    uint256 collateral_amount,
    uint256 usdtb_amount
  );

  /// @notice Event emitted when a supported asset is added
  event AssetAdded(address indexed asset);

  /// @notice Event emitted when a supported asset is removed
  event AssetRemoved(address indexed asset);

  /// @notice Event emitted when a benefactor address is added
  event BenefactorAdded(address indexed benefactor);

  /// @notice Event emitted when a beneficiary address is added or updated
  event BeneficiaryAdded(address indexed benefactor, address indexed beneficiary);

  /// @notice Event emitted when a benefactor address is removed
  event BenefactorRemoved(address indexed benefactor);

  /// @notice Event emitted when a beneficiary address is removed
  event BeneficiaryRemoved(address indexed benefactor, address indexed beneficiary);

  // @notice Event emitted when a custodian address is added
  event CustodianAddressAdded(address indexed custodian);

  // @notice Event emitted when a custodian address is removed
  event CustodianAddressRemoved(address indexed custodian);

  /// @notice Event emitted when assets are moved to custody provider wallet
  event CustodyTransfer(address indexed wallet, address indexed asset, uint256 amount);

  /// @notice Event emitted when USDtb is set
  event USDtbSet(address indexed USDtb);

  /// @notice Event emitted when the max mint per block is changed
  event MaxMintPerBlockChanged(uint256 oldMaxMintPerBlock, uint256 newMaxMintPerBlock, address indexed asset);

  /// @notice Event emitted when the max redeem per block is changed
  event MaxRedeemPerBlockChanged(uint256 oldMaxRedeemPerBlock, uint256 newMaxRedeemPerBlock, address indexed asset);

  /// @notice Event emitted when a delegated signer is added, enabling it to sign orders on behalf of another address
  event DelegatedSignerAdded(address indexed signer, address indexed delegator);

  /// @notice Event emitted when a delegated signer is removed
  event DelegatedSignerRemoved(address indexed signer, address indexed delegator);

  /// @notice Event emitted when a delegated signer is initiated
  event DelegatedSignerInitiated(address indexed signer, address indexed delegator);

  /// @notice Event emitted when the token type for a token is set.
  event TokenTypeSet(address indexed token, uint256 tokenType);

  /// @notice Event emitted when global max mint per block is modified.
  event GlobalMaxMintPerBlock(address indexed sender, uint128 globalMaxMintPerBlock);

  /// @notice Event emitted when global max redeem per block is modified.
  event GlobalMaxRedeemPerBlock(address indexed sender, uint128 globalMaxRedeemPerBlock);

  /// @notice Event emitted when global mint and redeem are disabled.
  event DisableMintRedeem(address indexed sender);
}
