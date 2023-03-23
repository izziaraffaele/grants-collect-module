// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployLensCollectVotingStrategyFactory is BaseDeployer {
  using stdJson for string;

  address collectModule;

  function loadBaseAddresses(string memory json, string memory targetEnv) internal override {
    collectModule = json.readAddress(string(abi.encodePacked(".", targetEnv, ".GitcoinCollectModule")));
  }

  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address strategyFactory = address(new LensCollectVotingStrategyFactory());
    LensCollectVotingStrategyFactory(strategyFactory).initialize();

    if (collectModule != address(0)) {
      LensCollectVotingStrategyFactory(strategyFactory).updateCollectModule(collectModule);
    }

    vm.stopBroadcast();

    return strategyFactory;
  }
}
