// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../BaseSetup.sol";
import {MockRoundImplementation} from "../mocks/MockRoundImplementation.sol";

import "../../src/interfaces/IGitcoinCollectModule.sol";
import "../../src/utils/MetaPtr.sol";
import {LensCollectVotingStrategyImplementation} from "../../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {GitcoinCollectModule} from "../../src/GitcoinCollectModule.sol";

contract LensCollectVotingStrategyImplementationBase is BaseSetup {
  struct VoteData {
    address token;
    uint256 amount;
    address grantAddress;
    bytes32 projectId;
    bytes32 pubId;
    uint256 collectTokenId;
  }

  uint16 constant REFERRAL_FEE_BPS = 250;

  address public votingStrategy;

  address public gitcoinCollectModule;

  address public roundImplementation;

  RoundApplicationData public exampleInitData;

  MetaPtr public exampleApplicationMetaPtr;

  VoteData public exampleVoteData;

  // Deploy & Whitelist BaseFeeCollectModule
  constructor() BaseSetup() {
    vm.startPrank(deployer);
    gitcoinCollectModule = address(new GitcoinCollectModule(hubProxyAddr));
    votingStrategy = address(new LensCollectVotingStrategyImplementation());
    roundImplementation = address(new MockRoundImplementation());

    LensCollectVotingStrategyImplementation(votingStrategy).initialize(hubProxyAddr, gitcoinCollectModule);
    MockRoundImplementation(roundImplementation).harnessSetVotingStrategy(votingStrategy);
    vm.stopPrank();

    vm.prank(governance);
    hub.whitelistCollectModule(gitcoinCollectModule, true);

    exampleApplicationMetaPtr = MetaPtr({
      protocol: 1,
      pointer: "bafybeiaoakfoxjwi2kwh43djbmomroiryvhv5cetg74fbtzwef7hzzvrnq"
    });

    exampleInitData.roundAddress = roundImplementation;
    exampleInitData.currency = address(currency);
    exampleInitData.referralFee = 0;
    exampleInitData.followerOnly = false;
    exampleInitData.applicationMetaPtr = exampleApplicationMetaPtr;
    exampleInitData.recipient = me;
  }

  function getEncodedInitData() internal virtual returns (bytes memory) {
    return abi.encode(exampleInitData);
  }

  function getEncodedVotes() internal virtual returns (bytes[] memory) {
    return
      _toBytesArray(
        abi.encode(
          exampleVoteData.token,
          exampleVoteData.amount,
          exampleVoteData.grantAddress,
          exampleVoteData.projectId,
          exampleVoteData.pubId,
          exampleVoteData.collectTokenId
        )
      );
  }
}
