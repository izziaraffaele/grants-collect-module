// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MetaPtr} from "../utils/MetaPtr.sol";

import {LensCollectVotingStrategyImplementation} from "./LensCollectVotingStrategyImplementation.sol";

contract LensCollectVotingStrategyFactory is OwnableUpgradeable {
  address public votingContract;

  // --- Event ---

  /// @notice Emitted when a Voting contract is updated
  event VotingContractUpdated(address votingContractAddress);

  /// @notice Emitted when a new Voting is created
  event VotingContractCreated(address indexed votingContractAddress, address indexed votingImplementation);

  /// @notice constructor function which ensure deployer is set as owner
  function initialize() external initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
  }

  // --- Core methods ---

  /**
   * @notice Allows the owner to update the QuadraticFundingVotingStrategyImplementation.
   * This provides us the flexibility to upgrade QuadraticFundingVotingStrategyImplementation
   * contract while relying on the same QuadraticFundingVotingStrategyFactory to get the list of
   * QuadraticFundingVoting contracts.
   */
  function updateVotingContract(address newVotingContract) external onlyOwner {
    // slither-disable-next-line missing-zero-check
    votingContract = newVotingContract;

    emit VotingContractUpdated(newVotingContract);
  }

  /**
   * @notice Clones QuadraticFundingVotingStrategyImplementation and deploys a contract
   * and emits an event
   */
  function create(address lensHub, address collectModule) external returns (address) {
    address clone = ClonesUpgradeable.clone(votingContract);
    emit VotingContractCreated(clone, votingContract);
    LensCollectVotingStrategyImplementation(clone).initialize(lensHub, collectModule);

    return clone;
  }
}
