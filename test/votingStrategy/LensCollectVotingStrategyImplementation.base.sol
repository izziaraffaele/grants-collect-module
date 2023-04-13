// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../BaseSetup.sol";

struct VoteData {
  address token;
  uint256 amount;
  address grantAddress;
  bytes32 projectId;
  uint256 applicationIndex;
  address voter;
}

contract LensCollectVotingStrategyImplementationBase is BaseSetup {
  uint16 constant REFERRAL_FEE_BPS = 250;

  VoteData public exampleVoteData;

  // Deploy & Whitelist BaseFeeCollectModule
  constructor() BaseSetup() {
    vm.prank(deployer);
    votingStrategy.initialize(collectModuleAddr);
  }

  function getEncodedVoteArrayData() internal virtual returns (bytes[] memory) {
    return
      _toBytesArray(
        abi.encode(
          exampleVoteData.token,
          exampleVoteData.amount,
          exampleVoteData.grantAddress,
          exampleVoteData.projectId,
          exampleVoteData.applicationIndex,
          exampleVoteData.voter
        )
      );
  }
}
