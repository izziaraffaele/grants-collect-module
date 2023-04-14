// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ProjectRegistry} from "allo/projectRegistry/ProjectRegistry.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployProjectRegistry is BaseDeployer {
  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address projectRegistry = address(new ProjectRegistry());
    ProjectRegistry(projectRegistry).initialize();

    vm.stopBroadcast();

    return projectRegistry;
  }
}
