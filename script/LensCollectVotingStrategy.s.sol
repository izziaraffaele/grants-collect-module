// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";
import "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import "./HelperConfig.sol";

contract DeployLensCollectVotingStrategy is Script, HelperConfig {
  function run() external {
    vm.startBroadcast();

    address implementation = address(new LensCollectVotingStrategyImplementation());
    LensCollectVotingStrategyFactory factory = new LensCollectVotingStrategyFactory();

    factory.initialize();
    factory.updateVotingContract(implementation);
    vm.stopBroadcast();
  }
}
