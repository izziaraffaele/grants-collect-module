// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Events {
  // --- Voting Strategy Factory events ---

  /// @notice Emitted when a Voting contract is updated
  event VotingContractUpdated(address votingContractAddress);

  /// @notice Emitted when a Voting contract is updated
  event CollectModuleUpdated(address collectModuleAddress);

  /// @notice Emitted when a new Voting is created
  event VotingContractCreated(address indexed votingContractAddress, address indexed votingImplementation);

  // --- Voting Strategy Implementation events ---

  /// @notice Emitted when a new vote is sent
  event Voted(
    address token, // voting token
    uint256 amount, // voting amount
    address indexed voter, // voter address
    address grantAddress, // grant address
    bytes32 indexed projectId, // project id
    uint256 applicationIndex, // application index
    address indexed roundAddress // round address
  );
}
