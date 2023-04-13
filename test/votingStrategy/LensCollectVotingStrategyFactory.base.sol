// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../BaseSetup.sol";

import {LensCollectVotingStrategyFactory} from "../../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

contract LensCollectVotingStrategyFactoryBase is BaseSetup {
  address votingContractAddr;

  LensCollectVotingStrategyFactory factory;

  constructor() BaseSetup() {
    vm.prank(deployer);
    factory = new LensCollectVotingStrategyFactory();

    votingContractAddr = address(votingStrategy);
  }
}
