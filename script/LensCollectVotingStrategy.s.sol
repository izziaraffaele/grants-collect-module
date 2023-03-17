// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {LensCollectVotingStrategyImplementation} from "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

import {BaseDeployScript} from "./BaseDeployScript.sol";
import "forge-std/Script.sol";

contract DeployLensCollectVotingStrategy is BaseDeployScript {
  constructor() BaseDeployScript() {
    // empty
  }

  function deploy() internal override {
    vm.startBroadcast();

    address strategyImpl = address(new LensCollectVotingStrategyImplementation());

    LensCollectVotingStrategyFactory factory = new LensCollectVotingStrategyFactory();
    factory.initialize();
    factory.updateVotingContract(strategyImpl);

    vm.stopBroadcast();
  }
}
