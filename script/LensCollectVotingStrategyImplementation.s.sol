// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";
import {LensCollectVotingStrategyImplementation} from "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployLensCollectVotingStrategyImplementation is BaseDeployer {
  using stdJson for string;

  address strategyFactory;

  function loadBaseAddresses(string memory json, string memory targetEnv) internal override {
    strategyFactory = json.readAddress(string(abi.encodePacked(".", targetEnv, ".LensCollectVotingStrategyFactory")));
  }

  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address strategyImpl = address(new LensCollectVotingStrategyImplementation());

    if (strategyFactory != address(0)) {
      LensCollectVotingStrategyFactory(strategyFactory).updateVotingContract(strategyImpl);
    }

    vm.stopBroadcast();

    return strategyImpl;
  }
}
