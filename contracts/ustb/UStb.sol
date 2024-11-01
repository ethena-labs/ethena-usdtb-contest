// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../SingleAdminAccessControlUpgradeable.sol";
import "./IUStbDefinitions.sol";

/**
 * @title UStb
 * @notice UStb rwa token contract
 */

contract UStb is ERC20BurnableUpgradeable, ERC20PermitUpgradeable, IUStbDefinitions, ReentrancyGuardUpgradeable, SingleAdminAccessControlUpgradeable {

  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice The role is allowed to mint UStb. To be pointed to UStb minting contract only.
  bytes32 public constant MINTER_CONTRACT = keccak256("MINTER_CONTRACT");
  /// @notice Role that can handle Blacklisting, in addition to admin role.
  bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
  /// @notice Role that can handle Whitelisting, in addition to admin role.
  bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
  /// @notice Blacklisted role restricts funds from being moved in and out of that address
  bytes32 public constant BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE");
  /// @notice During transferState 1, whitelisted role can still transfer
  bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

  TransferState public transferState;
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /* ------------- INITIALIZE ------------- */
  /**
   * @notice Initializer for UStb contract.
   * @param admin The address of the admin role.
   * @param minterContract The initial minterContract. Only this address can mint UStb
   */
  function initialize(address admin, address minterContract) public initializer {
    __ERC20_init("UStb", "UStb");
    __ERC20Permit_init("UStb");
    __ReentrancyGuard_init();
    if (admin == address(0) || minterContract == address(0)) revert ZeroAddressException();
    transferState = TransferState.FULLY_ENABLED;
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MINTER_CONTRACT, minterContract);
    emit MinterAdded(minterContract);
  }

  function addMinter(address minterContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_CONTRACT, minterContract);
    emit MinterAdded(minterContract);
  }

  function removeMinter(address minterContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_CONTRACT, minterContract);
    emit MinterRemoved(minterContract);
  }

  /**
  * @param users List of address to be blacklisted
  * @notice It is deemed acceptable for admin or access manager roles to be blacklisted accidentally since it does not affect operations.
  */
  function addBlacklistAddress(address[] calldata users) external onlyRole(BLACKLIST_MANAGER_ROLE) {
    for (uint8 i = 0; i < users.length; i++) {
      _grantRole(BLACKLISTED_ROLE, users[i]);
    }
  }

  /**
  * @param users List of address to be removed from blacklist
  */  
  function removeBlacklistAddress(address[] calldata users) external onlyRole(BLACKLIST_MANAGER_ROLE) {
    for (uint8 i = 0; i < users.length; i++) {
      _revokeRole(BLACKLISTED_ROLE, users[i]);
    }
  }

  /**
  * @param users List of address to be whitelist
  */
  function addWhitelistAddress(address[] calldata users) external onlyRole(WHITELIST_MANAGER_ROLE) {
    for (uint8 i = 0; i < users.length; i++) {
      _grantRole(WHITELISTED_ROLE, users[i]);
    }
  }

  /**
  * @param users List of address to be removed from whitelist
  */  
  function removeWhitelistAddress(address[] calldata users) external onlyRole(WHITELIST_MANAGER_ROLE) {
    for (uint8 i = 0; i < users.length; i++) {
      _revokeRole(WHITELISTED_ROLE, users[i]);
    }
  }

  /**
   * @dev Burns the blacklisted user UStb and mints to the desired owner address.
   * @param from The address to burn the entire balance, with the BLACKLISTED_ROLE
   * @param to The address to mint the entire balance of "from" parameter.
   */
  function redistributeLockedAmount(address from, address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (hasRole(BLACKLISTED_ROLE, from) && !hasRole(BLACKLISTED_ROLE, to)) {
      uint256 amountToDistribute = balanceOf(from);
      _burn(from, amountToDistribute);
      _mint(to, amountToDistribute);
      emit LockedAmountRedistributed(from, to, amountToDistribute);
    } else {
      revert OperationNotAllowed();
    }
  }

  /**
   * @notice Allows the owner to rescue tokens accidentally sent to the contract.
   * @param token The token to be rescued.
   * @param amount The amount of tokens to be rescued.
   * @param to Where to send rescued tokens
   */
  function rescueTokens(address token, uint256 amount, address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20Upgradeable(token).safeTransfer(to, amount);
    emit TokensRescued(token, to, amount);
  }

  /**
   * @notice Mints new UStb tokens
   * @param to The address to mint tokens to
   * @param amount The amount of tokens to mint
   * @dev Only callable by MINTER_CONTRACT role
   */
  function mint(address to, uint256 amount) external onlyRole(MINTER_CONTRACT) {
    _mint(to, amount);
  }

  /**
   * @dev Remove renounce role access from AccessControl, to prevent users to resign roles.
   * @notice It's deemed preferable security-wise to ensure the contract maintains an owner, 
   * over the ability to renounce roles, role renunciation can be achieved via owner revoking the role.
   */
  function renounceRole(bytes32, address) public virtual override {
    revert OperationNotAllowed();
  }

  /**
   * @param code Admin can disable all transfers, allow limited addresses only, or fully enable transfers
   */  
  function updateTransferState(TransferState code) external onlyRole(DEFAULT_ADMIN_ROLE) {
    TransferState prevState = transferState;
    transferState = code;
    emit TransferStateUpdated(prevState, code);
  }

  function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
    // State 2 - Transfers fully enabled except for blacklisted addresses
    if (transferState == TransferState.FULLY_ENABLED) {
      if (hasRole(MINTER_CONTRACT, msg.sender) && !hasRole(BLACKLISTED_ROLE, from) && to == address(0)) {
        // redeeming
      } else if (hasRole(MINTER_CONTRACT, msg.sender) && from == address(0) && !hasRole(BLACKLISTED_ROLE, to)) {
        // minting
      } else if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && hasRole(BLACKLISTED_ROLE, from) && to == address(0)) {
        // redistributing - burn
      } else if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && from == address(0) && !hasRole(BLACKLISTED_ROLE, to)) {
        // redistributing - mint
      } else if (!hasRole(BLACKLISTED_ROLE, msg.sender) && !hasRole(BLACKLISTED_ROLE, from) && !hasRole(BLACKLISTED_ROLE, to)) {
        // normal case
      } else {
        revert OperationNotAllowed();
      }
    // State 1 - Transfers only enabled between whitelisted addresses
    } else if (transferState == TransferState.WHITELIST_ENABLED) {
      if (hasRole(MINTER_CONTRACT, msg.sender) && !hasRole(BLACKLISTED_ROLE, from) && to == address(0)) {
        // redeeming
      } else if (hasRole(MINTER_CONTRACT, msg.sender) && from == address(0) && !hasRole(BLACKLISTED_ROLE, to)) {
        // minting
      } else if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && hasRole(BLACKLISTED_ROLE, from) && to == address(0)) {
        // redistributing - burn
      } else if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && from == address(0) && !hasRole(BLACKLISTED_ROLE, to)) {
        // redistributing - mint
      } else if (hasRole(WHITELISTED_ROLE, msg.sender) && hasRole(WHITELISTED_ROLE, from) && to == address(0)) {
        // whitelisted user can burn
      } else if (hasRole(WHITELISTED_ROLE, msg.sender) && hasRole(WHITELISTED_ROLE, from) && hasRole(WHITELISTED_ROLE, to) && !hasRole(BLACKLISTED_ROLE, msg.sender) && !hasRole(BLACKLISTED_ROLE, from) && !hasRole(BLACKLISTED_ROLE, to)) {
        // n.b. an address can be whitelisted and blacklisted at the same time
        // normal case
      } else {
        revert OperationNotAllowed();
      }
    // State 0 - Fully disabled transfers
    } else if (transferState == TransferState.FULLY_DISABLED) {
      revert OperationNotAllowed();
    } 
  }
}
