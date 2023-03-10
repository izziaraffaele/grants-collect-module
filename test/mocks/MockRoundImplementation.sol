// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "../../src/interfaces/IVotingStrategy.sol";
import "../../src/interfaces/IRoundImplementation.sol";
import "../../src/utils/MetaPtr.sol";

contract MockRoundImplementation is IRoundImplementation, AccessControlEnumerable {
  bytes32 public constant ROUND_OPERATOR_ROLE = keccak256("ROUND_OPERATOR");

  IVotingStrategy public votingStrategy;

  // --- Harness methods methods ---

  function harnessSetVotingStrategy(address _votingStrategy) external {
    votingStrategy = IVotingStrategy(_votingStrategy);
    votingStrategy.init();
  }

  // --- Core methods ---

  function applyToRound(bytes32 projectID, MetaPtr calldata newApplicationMetaPtr) external view {
    // empty
  }

  function vote(bytes[] memory encodedVotes) external payable {
    votingStrategy.vote{value: msg.value}(encodedVotes, msg.sender);
  }
}
