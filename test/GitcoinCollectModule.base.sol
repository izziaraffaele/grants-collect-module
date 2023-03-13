// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./BaseSetup.sol";
import {MockRoundImplementation} from "./mocks/MockRoundImplementation.sol";

import "../src/interfaces/IGitcoinCollectModule.sol";
import "../src/utils/MetaPtr.sol";
import {LensCollectVotingStrategyImplementation} from "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {GitcoinCollectModule} from "../src/GitcoinCollectModule.sol";

contract GitcoinCollectModuleBase is BaseSetup {
  uint16 constant REFERRAL_FEE_BPS = 250;

  address public votingStrategy;

  address public gitcoinCollectModule;

  address public roundImplementation;

  RoundApplicationData public exampleInitData;

  MetaPtr public exampleApplicationMetaPtr;

  // Deploy & Whitelist BaseFeeCollectModule
  constructor() BaseSetup() {
    vm.startPrank(deployer);
    gitcoinCollectModule = address(new GitcoinCollectModule(hubProxyAddr));
    votingStrategy = address(new LensCollectVotingStrategyImplementation());
    roundImplementation = address(new MockRoundImplementation());

    LensCollectVotingStrategyImplementation(votingStrategy).initialize(gitcoinCollectModule);
    MockRoundImplementation(roundImplementation).harnessSetVotingStrategy(votingStrategy);
    vm.stopPrank();

    vm.prank(governance);
    hub.whitelistCollectModule(gitcoinCollectModule, true);

    exampleApplicationMetaPtr = MetaPtr({
      protocol: 1,
      pointer: "bafybeiaoakfoxjwi2kwh43djbmomroiryvhv5cetg74fbtzwef7hzzvrnq"
    });
  }

  function getEncodedInitData() internal virtual returns (bytes memory) {
    return abi.encode(exampleInitData);
  }
}
