// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./BaseSetup.sol";

import {LensCollectVotingStrategyImplementation} from "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";

contract GitcoinCollectModuleBase is BaseSetup {
  uint16 constant REFERRAL_FEE_BPS = 250;

  DataTypes.ProfilePublicationInitData public exampleInitData;

  // Deploy & Whitelist BaseFeeCollectModule
  constructor() BaseSetup() {
    vm.prank(deployer);
    votingStrategy.initialize(collectModuleAddr);
  }

  function getEncodedInitData() internal virtual returns (bytes memory) {
    return abi.encode(exampleInitData);
  }
}
