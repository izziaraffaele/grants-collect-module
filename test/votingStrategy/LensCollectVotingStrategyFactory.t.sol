// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {LensCollectVotingStrategyImplementation} from "../../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {LensCollectVotingStrategyFactory} from "../../src/votingStrategy/LensCollectVotingStrategyFactory.sol";
import {GitcoinCollectModule} from "../../src/GitcoinCollectModule.sol";

contract LensCollectVotingStrategyFactoryBase is Test {
  address deployer = address(1);
  address collectModule = address(2);
  address votingContract;

  LensCollectVotingStrategyFactory factory;

  constructor() Test() {
    vm.startPrank(deployer);
    votingContract = address(new LensCollectVotingStrategyImplementation());

    factory = new LensCollectVotingStrategyFactory();
    vm.stopPrank();
  }
}

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
  /// @notice Emitted when a Voting contract is updated
  event VotingContractUpdated(address votingContractAddress);

  /// @notice Emitted when a Voting contract is updated
  event CollectModuleUpdated(address collectModuleAddress);

  constructor() LensCollectVotingStrategyFactoryBase() {
    vm.prank(deployer);
    factory.initialize();
  }

  function testCannotUpdateVotingContractWhenNotOwner() external {
    vm.expectRevert();
    factory.updateVotingContract(votingContract);
  }

  function testCannotUpdateCollectModuleContractWhenNotOwner() external {
    vm.expectRevert();
    factory.updateCollectModule(collectModule);
  }

  function testUpdateVotingContractShouldEmitExpectedEvents() external {
    vm.expectEmit(true, true, true, true);
    emit VotingContractUpdated(votingContract);

    vm.prank(deployer);
    factory.updateVotingContract(votingContract);
  }

  function testUpdateCollectModuleShouldEmitExpectedEvents() external {
    vm.expectEmit(true, true, true, true);
    emit CollectModuleUpdated(collectModule);

    vm.prank(deployer);
    factory.updateCollectModule(collectModule);
  }

  function testUpdateShouldUpdateExpectedValues() external {
    vm.prank(deployer);
    factory.updateVotingContract(votingContract);
    assertEq(factory.votingContract(), votingContract);

    vm.prank(deployer);
    factory.updateCollectModule(collectModule);
    assertEq(factory.collectModule(), collectModule);
  }
}

contract LensCollectVotingStrategyFactory_Create is LensCollectVotingStrategyFactoryBase {
  constructor() LensCollectVotingStrategyFactoryBase() {
    vm.prank(deployer);
    factory.initialize();
  }

  function setUp() external {
    vm.startPrank(deployer);
    factory.updateVotingContract(votingContract);
    factory.updateCollectModule(collectModule);
    vm.stopPrank();
  }

  function testCreateReturnsVotingInstanceAddress() external {
    address votingAddress = factory.create();
    assert(votingAddress != address(0));
  }

  function testCreateInitializedVotingInstance() external {
    address votingAddress = factory.create();

    address initCollectModule = LensCollectVotingStrategyImplementation(votingAddress).collectModule();
    assertEq(initCollectModule, collectModule);
  }

  // function testCreateEmitExpectedEvents() {
  //   vm.expectEmit(true, true, true, true, factory);

  //   emit LensCollectVotingStrategyFactory.VotingContractCreated(votingContract);

  //   factory.create();
  // }
}
