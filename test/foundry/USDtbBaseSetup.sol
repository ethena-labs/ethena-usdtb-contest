// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* solhint-disable private-vars-leading-underscore  */
/* solhint-disable func-name-mixedcase  */
/* solhint-disable var-name-mixedcase  */

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import "../../contracts/interfaces/ISingleAdminAccessControl.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {Upgrades} from "../../contracts/lib/Upgrades.sol";
import {USDtb} from "../../contracts/usdtb/USDtb.sol";
import {IUSDtb} from "../../contracts/usdtb/IUSDtb.sol";

import "../../test/utils/SigUtils.sol";

contract USDtbBaseSetup is Test {
  struct USDtbDeploymentAddresses {
    address proxyAddress;
    address USDtbImplementation;
    address admin;
    address proxyAdminAddress;
  }

  USDtbDeploymentAddresses internal USDtbDeploymentAddressesInstance;
  ITransparentUpgradeableProxy internal USDtbContractAsProxy;
  ProxyAdmin proxyAdminContract;
  USDtb internal USDtbContract;

  uint256 internal proxyAdminOwnerPrivateKey;
  uint256 internal USDtbProxyStandardOwnerPrivateKey;
  uint256 internal newOwnerPrivateKey;
  uint256 internal minterPrivateKey;
  uint256 internal bobPrivateKey;
  uint256 internal gregPrivateKey;
  uint256 internal randomerPrivateKey;
  uint256 internal USDtbDeployerPrivateKey;
  uint256 internal minterContractPrivateKey;
  uint256 internal alicePrivateKey;

  address internal proxyAdminOwner;
  address internal USDtbProxyStandardOwner;
  address internal newOwner;
  address internal minter_contract;
  address internal minter;
  address internal bob;
  address internal randomer;
  address internal greg;
  address internal alice;
  address internal DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  address internal NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  uint256 public _amount = 100 ether;
  uint256 public _transferAmount = 7 ether;

  // Roles references
  bytes32 internal adminRole = 0x00;
  bytes32 internal DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 internal BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
  bytes32 internal WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
  bytes32 internal BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE");
  bytes32 internal WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
  bytes32 internal MINTER_CONTRACT = keccak256("MINTER_CONTRACT");

  address constant _DESIRED_PROXY_OWNER = address(0x3B0AAf6e6fCd4a7cEEf8c92C32DFeA9E64dC1862);
  address constant _IMPLEMENTATION_OWNER = address(0x0000000000000000000000000000000000000001);

  SigUtils public sigUtils;

  function setUp() public virtual {
    proxyAdminOwnerPrivateKey = 0xA21CE;
    USDtbProxyStandardOwnerPrivateKey = 0xA11CE;
    newOwnerPrivateKey = 0xA14CE;
    minterPrivateKey = 0xB44DE;
    bobPrivateKey = 0x1DEA2;
    gregPrivateKey = 0x6ED;
    randomerPrivateKey = 0x1DECC;
    minterContractPrivateKey = 0x1DEA3;
    USDtbDeployerPrivateKey = uint256(keccak256(abi.encodePacked("USDtbDeployer")));
    alicePrivateKey = 0xB44DE1;

    proxyAdminOwner = vm.addr(proxyAdminOwnerPrivateKey);
    // Wallet that is allowed to call the ownable methods of the implementation contract
    // this wallet is NOT the proxy admin owner who is allowed to call the proxy admin methods
    USDtbProxyStandardOwner = vm.addr(USDtbProxyStandardOwnerPrivateKey);
    newOwner = vm.addr(newOwnerPrivateKey);
    minter = vm.addr(minterPrivateKey);
    bob = vm.addr(bobPrivateKey);
    greg = vm.addr(gregPrivateKey);
    randomer = vm.addr(randomerPrivateKey);
    alice = vm.addr(alicePrivateKey);
    minter_contract = vm.addr(minterContractPrivateKey);

    vm.label(USDtbProxyStandardOwner, "USDtbProxyStandardOwner");
    vm.label(bob, "bob");
    vm.label(randomer, "randomer");
    vm.label(greg, "greg");
    vm.label(minter_contract, "minter_contract");
    vm.label(proxyAdminOwner, "proxyAdminOwner");
    vm.label(alice, "alice");

    address deployerAddress = vm.addr(USDtbDeployerPrivateKey);

    vm.startBroadcast(USDtbDeployerPrivateKey);

    proxyAdminContract = new ProxyAdmin();

    // Covers the case where we deploy the contract with an address that is not the desired proxy admin owner
    if (deployerAddress != proxyAdminOwner) {
      proxyAdminContract.transferOwnership(proxyAdminOwner);
    }

    USDtbDeploymentAddressesInstance.proxyAdminAddress = address(proxyAdminContract);

    USDtbDeploymentAddressesInstance.proxyAddress = Upgrades.deployTransparentProxy(
      "USDtb.sol",
      address(USDtbDeploymentAddressesInstance.proxyAdminAddress),
      abi.encodeCall(USDtb.initialize, (newOwner, minter_contract))
    );

    USDtbContractAsProxy = ITransparentUpgradeableProxy(payable(USDtbDeploymentAddressesInstance.proxyAddress));

    USDtbDeploymentAddressesInstance.USDtbImplementation =
      Upgrades.getImplementationAddress(USDtbDeploymentAddressesInstance.proxyAddress);

    USDtbDeploymentAddressesInstance.admin = Upgrades.getAdminAddress(USDtbDeploymentAddressesInstance.proxyAddress);

    USDtbContract = USDtb(USDtbDeploymentAddressesInstance.proxyAddress);

    vm.stopBroadcast();

    vm.startPrank(minter_contract);
    USDtbContract.mint(alice, _amount);
    USDtbContract.mint(bob, _amount);
    USDtbContract.mint(greg, _amount);
    vm.stopPrank();
  }
}
