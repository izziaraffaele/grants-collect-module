// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import "./HelperConfig.sol";

abstract contract BaseDeployScript is Script, HelperConfig {
  address deployer;

  constructor() HelperConfig() {
    // empty
  }

  function run() external {
    loadPrivateKeys();
    deploy();
  }

  function loadPrivateKeys() internal {
    deployer = msg.sender;
    console.log("\nDeployer address:", deployer);
    console.log("Deployer balance:", deployer.balance);
  }

  function deploy() internal virtual;
}
