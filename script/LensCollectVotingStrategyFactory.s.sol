// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployLensCollectVotingStrategyFactory is BaseDeployer {
  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address strategyFactory = address(new LensCollectVotingStrategyFactory());
    LensCollectVotingStrategyFactory(strategyFactory).initialize();

    vm.stopBroadcast();

    return strategyFactory;
  }
}
