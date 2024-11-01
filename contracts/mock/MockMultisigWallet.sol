// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// console.log
import "forge-std/Script.sol";

contract MockMultiSigWallet is IERC1271, AccessControl {
  using ECDSA for bytes32;

  bytes4 internal constant MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
  bytes4 internal constant INVALID_SIGNATURE = 0xffffffff;

  uint256 minimumSignatures = 2;
  mapping(bytes32 => uint256) public messageSignatures;
  mapping(bytes32 => mapping(address => bool)) private _signers;

  bytes32 public constant SMART_CONTRACT_SIGNER = keccak256("SMART_CONTRACT_SIGNER_ROLE");

  constructor(address owner, address signer1, address signer2) {
    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    _grantRole(SMART_CONTRACT_SIGNER, signer1);
    _grantRole(SMART_CONTRACT_SIGNER, signer2);
  }

  function submitSignature(bytes32 _messageHash, bytes memory _signature) public {
    address signer = _messageHash.recover(_signature);
    console.log("EIP 1271 signer recover: %s", signer);
    require(hasRole(SMART_CONTRACT_SIGNER, signer), "Caller must have SMART_CONTRACT_SIGNER role");
    if (!_signers[_messageHash][signer]) {
      _signers[_messageHash][signer] = true;
      messageSignatures[_messageHash] += 1;
    }
  }

  function isValidSignature(bytes32 _messageHash, bytes memory _signature)
    public
    view
    override
    returns (bytes4 magicValue)
  {
    address signer = _messageHash.recover(_signature);
    if (
      messageSignatures[_messageHash] >= minimumSignatures && hasRole(SMART_CONTRACT_SIGNER, signer)
        && _signers[_messageHash][signer]
    ) {
      return MAGICVALUE;
    } else {
      return INVALID_SIGNATURE;
    }
  }

  function approveERC20(address token, address spender, uint256 amount) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Approver must have DEFAULT_ADMIN_ROLE role");
    IERC20(token).approve(spender, amount);
  }
}
