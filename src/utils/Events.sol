// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Events {
  /// @notice Emitted when a new vote is sent
  event Voted(
    address token, // voting token
    uint256 amount, // voting amount
    address indexed voter, // voter address
    address grantAddress, // grant address
    bytes32 indexed projectId, // project id
    address indexed roundAddress // round address
  );
}
