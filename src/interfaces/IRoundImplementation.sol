// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IRoundImplementation {
  function getApplicationStatus(uint256 applicationIndex) external view returns (uint256);

  function vote(bytes[] memory encodedVotes) external payable;
}
