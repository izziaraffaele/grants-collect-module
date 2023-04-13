// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/interfaces/ILensCollectVotingStrategy.sol";
import "../../src/interfaces/IRoundImplementation.sol";

contract MockRoundImplementation is IRoundImplementation {
  ILensCollectVotingStrategy votingStrategy;

  mapping(uint256 => uint256) internal _applications;

  function setVotingStrategy(address _votingStrategy) external {
    votingStrategy = ILensCollectVotingStrategy(_votingStrategy);
    votingStrategy.init();
  }

  function setApplicationStatus(uint256 applicationIndex, uint256 status) external {
    _applications[applicationIndex] = status;
  }

  function getApplicationStatus(uint256 applicationIndex) external view returns (uint256) {
    return _applications[applicationIndex];
  }

  function vote(bytes[] memory encodedVotes) external payable {
    votingStrategy.vote{value: msg.value}(encodedVotes, msg.sender);
  }
}
