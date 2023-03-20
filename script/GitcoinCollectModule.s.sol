// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {GitcoinCollectModule} from "../src/GitcoinCollectModule.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployGitcoinCollectModule is BaseDeployer {
  using stdJson for string;

  address lensHubProxy;

  function loadBaseAddresses(string memory json, string memory targetEnv) internal override {
    lensHubProxy = json.readAddress(string(abi.encodePacked(".", targetEnv, ".LensHubProxy")));
  }

  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address collectModule = address(new GitcoinCollectModule(lensHubProxy));

    vm.stopBroadcast();

    return collectModule;
  }
}
