// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../BaseSetup.sol";
import {LensCollectVotingStrategyFactoryBase} from "./LensCollectVotingStrategyFactory.base.sol";

import {LensCollectVotingStrategyFactory} from "../../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

contract LensCollectVotingStrategyFactory_Initialize is LensCollectVotingStrategyFactoryBase {
  constructor() LensCollectVotingStrategyFactoryBase() {
    // empty
  }

  function setUp() external {
    vm.prank(deployer);
    factory.initialize();
  }

  function testCannotInitTwice() external {
    vm.expectRevert("Initializable: contract is already initialized");
    factory.initialize();
  }

  function testInitializeShouldSetOwner() external {
    assertEq(factory.owner(), deployer);
  }
}

contract LensCollectVotingStrategyFactory_Update is LensCollectVotingStrategyFactoryBase {
  constructor() LensCollectVotingStrategyFactoryBase() {
    vm.prank(deployer);
    factory.initialize();
  }

  function testCannotUpdateVotingContractWhenNotOwner() external {
    vm.expectRevert();
    factory.updateVotingContract(votingContractAddr);
  }

  function testCannotUpdateCollectModuleContractWhenNotOwner() external {
    vm.expectRevert();
    factory.updateCollectModule(collectModuleAddr);
  }

  function testUpdateVotingContractShouldEmitExpectedEvents() external {
    vm.expectEmit(true, true, true, true);
    emit Events.VotingContractUpdated(votingContractAddr);

    vm.prank(deployer);
    factory.updateVotingContract(votingContractAddr);
  }

  function testUpdateCollectModuleShouldEmitExpectedEvents() external {
    vm.expectEmit(true, true, true, true);
    emit Events.CollectModuleUpdated(collectModuleAddr);

    vm.prank(deployer);
    factory.updateCollectModule(collectModuleAddr);
  }

  function testUpdateShouldUpdateExpectedValues() external {
    vm.prank(deployer);
    factory.updateVotingContract(votingContractAddr);
    assertEq(factory.votingContract(), votingContractAddr);

    vm.prank(deployer);
    factory.updateCollectModule(collectModuleAddr);
    assertEq(factory.collectModule(), collectModuleAddr);
  }
}

contract LensCollectVotingStrategyFactory_Create is LensCollectVotingStrategyFactoryBase {
  constructor() LensCollectVotingStrategyFactoryBase() {
    vm.prank(deployer);
    factory.initialize();
  }

  function setUp() external {
    vm.startPrank(deployer);
    factory.updateVotingContract(votingContractAddr);
    factory.updateCollectModule(collectModuleAddr);
    vm.stopPrank();
  }

  function testCreateReturnsVotingInstanceAddress() external {
    address _votingStrategy = factory.create();
    assert(_votingStrategy != address(0));
  }

  function testCreateInitializedVotingInstance() external {
    address _votingStrategy = factory.create();

    address initCollectModule = LensCollectVotingStrategyImplementation(_votingStrategy).collectModule();
    assertEq(initCollectModule, collectModuleAddr);
  }

  // function testCreateEmitExpectedEvents() {
  //   vm.expectEmit(true, true, true, true, factory);

  //   emit LensCollectVotingStrategyFactory.VotingContractCreated(votingContract);

  //   factory.create();
  // }
}
