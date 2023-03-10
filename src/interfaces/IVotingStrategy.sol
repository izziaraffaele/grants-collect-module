// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @notice Gitcoin grants voting strategy interface.
 */
interface IVotingStrategy {
  /**
   * @notice Invoked by RoundImplementation on creation to
   * set the round for which the voting contracts is to be used
   *
   */
  function init() external;

  /**
   * @notice Invoked by RoundImplementation to allow voter to case
   * vote for grants during a round.
   *
   * @dev
   * - allows contributor to do cast multiple votes which could be weighted.
   * - should be invoked by RoundImplementation contract
   * - ideally IVotingStrategy implementation should emit events after a vote is cast
   * - this would be triggered when a voter casts their vote via grant explorer or lens collect module
   *
   * @param _encodedVotes encoded votes
   * @param _voterAddress voter address
   */
  function vote(bytes[] calldata _encodedVotes, address _voterAddress) external payable;
}
