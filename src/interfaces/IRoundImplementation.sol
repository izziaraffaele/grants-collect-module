// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {MetaPtr} from "../utils/MetaPtr.sol";

/**
 * @notice Gitcoin grants implementation interface.
 */
interface IRoundImplementation {
  /// @notice Submit a project application
  /// @param projectID unique hash of the project (user id in case of a lens publication)
  /// @param newApplicationMetaPtr appliction metaPtr
  function applyToRound(bytes32 projectID, MetaPtr calldata newApplicationMetaPtr) external;

  /// @notice Invoked by voter to cast votes
  /// @param encodedVotes encoded vote
  function vote(bytes[] calldata encodedVotes) external payable;
}
