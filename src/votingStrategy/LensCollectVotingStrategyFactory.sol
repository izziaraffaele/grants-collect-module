// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ILensCollectVotingStrategy} from "../interfaces/ILensCollectVotingStrategy.sol";
import {Events} from "../libraries/Events.sol";

contract LensCollectVotingStrategyFactory is OwnableUpgradeable {
  address public votingContract;

  address public collectModule;

  /// @notice constructor function which ensure deployer is set as owner
  function initialize() external initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
  }

  // --- Core methods ---

  /**
   * @notice Allows the owner to update the LensCollectVotingStrategyImplementation.
   * This provides us the flexibility to upgrade LensCollectVotingStrategyImplementation
   * contract while relying on the same LensCollectVotingStrategyFactory to get the list of
   * QuadraticFundingVoting contracts.
   */
  function updateVotingContract(address newVotingContract) external onlyOwner {
    // slither-disable-next-line missing-zero-check
    votingContract = newVotingContract;

    emit Events.VotingContractUpdated(newVotingContract);
  }

  /**
   * @notice Allows the owner to update the Lens collect module used to initialize the strategy.
   */
  function updateCollectModule(address newCollectModule) external onlyOwner {
    // slither-disable-next-line missing-zero-check
    collectModule = newCollectModule;

    emit Events.CollectModuleUpdated(newCollectModule);
  }

  /**
   * @notice Clones QuadraticFundingVotingStrategyImplementation and deploys a contract
   * and emits an event
   */
  function create() external returns (address) {
    // create voting strategy
    address clone = ClonesUpgradeable.clone(votingContract);
    emit Events.VotingContractCreated(clone, votingContract);

    // initialize voting strategy
    ILensCollectVotingStrategy(clone).initialize(collectModule);

    return clone;
  }
}
