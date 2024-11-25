// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* solhint-disable var-name-mixedcase  */

import "./IUSDtbMintingEvents.sol";

interface IUSDtbMinting is IUSDtbMintingEvents {
  enum Role {
    Minter,
    Redeemer
  }

  enum OrderType {
    MINT,
    REDEEM
  }

  enum TokenType {
    STABLE,
    ASSET
  }

  enum SignatureType {
    EIP712,
    EIP1271
  }

  enum DelegatedSignerStatus {
    REJECTED,
    PENDING,
    ACCEPTED
  }

  struct Signature {
    SignatureType signature_type;
    bytes signature_bytes;
  }

  struct Route {
    address[] addresses;
    uint128[] ratios;
  }

  struct Order {
    string order_id;
    OrderType order_type;
    uint120 expiry;
    uint128 nonce;
    address benefactor;
    address beneficiary;
    address collateral_asset;
    uint128 collateral_amount;
    uint128 usdtb_amount;
  }

  struct TokenConfig {
    /// @notice tracks asset type (STABLE or ASSET)
    TokenType tokenType;
    /// @notice tracks if the asset is active
    bool isActive;
    /// @notice max mint per block this given asset
    uint128 maxMintPerBlock;
    /// @notice max redeem per block this given asset
    uint128 maxRedeemPerBlock;
  }

  struct BlockTotals {
    /// @notice USDtb minted per block / per asset per block
    uint128 mintedPerBlock;
    /// @notice USDtb redeemed per block / per asset per block
    uint128 redeemedPerBlock;
  }

  struct GlobalConfig {
    /// @notice max USDtb that can be minted across all assets within a single block.
    uint128 globalMaxMintPerBlock;
    /// @notice max USDtb that can be redeemed across all assets within a single block.
    uint128 globalMaxRedeemPerBlock;
  }

  error InvalidAddress();
  error InvalidUSDtbAddress();
  error InvalidZeroAddress();
  error InvalidAssetAddress();
  error InvalidBenefactorAddress();
  error InvalidBeneficiaryAddress();
  error InvalidCustodianAddress();
  error InvalidOrder();
  error InvalidAmount();
  error InvalidRoute();
  error InvalidStablePrice();
  error UnknownSignatureType();
  error UnsupportedAsset();
  error NoAssetsProvided();
  error BenefactorNotWhitelisted();
  error BeneficiaryNotApproved();
  error InvalidEIP712Signature();
  error InvalidEIP1271Signature();
  error InvalidNonce();
  error SignatureExpired();
  error TransferFailed();
  error DelegationNotInitiated();
  error MaxMintPerBlockExceeded();
  error MaxRedeemPerBlockExceeded();
  error GlobalMaxMintPerBlockExceeded();
  error GlobalMaxRedeemPerBlockExceeded();

  function hashOrder(Order calldata order) external view returns (bytes32);

  function verifyOrder(Order calldata order, Signature calldata signature) external view returns (bytes32);

  function verifyRoute(Route calldata route) external view returns (bool);

  function verifyNonce(address sender, uint128 nonce) external view returns (uint128, uint256, uint256);

  function verifyStablesLimit(
    uint128 collateralAmount,
    uint128 usdtbAmount,
    address collateralAsset,
    OrderType orderType
  ) external view returns (bool);

  function mint(Order calldata order, Route calldata route, Signature calldata signature) external;

  function redeem(Order calldata order, Signature calldata signature) external;
}
