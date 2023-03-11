// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {LensCollectVotingStrategyImplementation} from "../../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {LensCollectVotingStrategyFactory} from "../../src/votingStrategy/LensCollectVotingStrategyFactory.sol";
import {GitcoinCollectModule} from "../../src/GitcoinCollectModule.sol";

contract LensCollectVotingStrategyFactory_Create is Test {
  address deployer = address(1);
  address lensHub = address(1);
  address collectModule = address(1);

  LensCollectVotingStrategyFactory factory;
  address votingContract;

  constructor() Test() {
    vm.startPrank(deployer);
    votingContract = address(new LensCollectVotingStrategyImplementation());

    factory = new LensCollectVotingStrategyFactory();
    factory.initialize();
    factory.updateVotingContract(votingContract);
    vm.stopPrank();
  }

  function testCreateShouldInitializeImplementation() public virtual {
    address votingStrategy = factory.create(lensHub, collectModule);

    assertEq(LensCollectVotingStrategyImplementation(votingStrategy).collectModule(), collectModule);
    assertEq(LensCollectVotingStrategyImplementation(votingStrategy).lensHub(), lensHub);
  }
}
