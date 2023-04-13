// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// prettier-ignore
import {
  SafeERC20Upgradeable,
  IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {ILensCollectVotingStrategy} from "../interfaces/ILensCollectVotingStrategy.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";

/**
 * @notice Gitcoin grants round voting strategy. This is a modified version of the
 * QuadraticFundingVotingStrategyImplementation.sol from Gitcoin grants repository
 *
 * @author Izzia Raffaele (https://github.com/izziaraffaele/grants-collect-module)
 * @author Modified from Gitcoin (https://github.com/gitcoinco/grants-stack)
 */
contract LensCollectVotingStrategyImplementation is
  ILensCollectVotingStrategy,
  Initializable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // --- Constants ---

  string public constant VERSION = "0.2.0";

  // --- Data ---

  /// @notice The current collect module
  address public collectModule;

  /// @notice The round contract address
  address public roundAddress;

  // --- Modifiers ---

  modifier onlyRoundContract() {
    if (msg.sender != roundAddress) {
      revert Errors.NotRoundContract();
    }
    _;
  }

  // --- Core methods ---

  /**
   * @notice Invoked by RoundImplementation on creation to
   * set the round for which the voting contracts is to be used
   *
   */
  function init() external override {
    if (roundAddress != address(0)) {
      revert Errors.Initialized();
    }

    roundAddress = msg.sender;
  }

  /**
   * @notice Invoked by LensCollectVotingStrategyFactory on creation to
   * set the round for which the voting contracts is to be used
   *
   * @param _collectModule Address of the associated collect module
   */
  function initialize(address _collectModule) external initializer {
    if (collectModule != address(0)) {
      revert Errors.Initialized();
    }

    collectModule = _collectModule;
  }

  /**
   * @notice Invoked by RoundImplementation to allow voter to case
   * vote for grants during a round.
   *
   * @dev
   * - allows contributor to do cast multiple votes which could be weighted.
   * - should be invoked by RoundImplementation contract
   * - ideally IVotingStrategy implementation should emit events after a vote is cast
   * - this would be triggered when a voter casts their vote via grant explorer or lens collect module
   * - votes contains pubId or collectIndex should be considered casted via lens collect module
   *
   * @param encodedVotes encoded votes
   * @param voterAddress voter address
   */
  function vote(
    bytes[] calldata encodedVotes,
    address voterAddress
  ) external payable override nonReentrant onlyRoundContract {
    /// @dev iterate over multiple donations and process each contribution
    for (uint256 i = 0; i < encodedVotes.length; i++) {
      _processContribution(encodedVotes[i], voterAddress);
    }
  }

  function _processContribution(bytes memory data, address caller) internal {
    (
      address _token,
      uint256 _amount,
      address _grantAddress,
      bytes32 _projectId,
      uint256 _applicationIndex,
      address _voter
    ) = _getContributionData(data, caller);

    // if the vote was not submitted through Lens we need to transfer tokens
    // from the voter to the grant address
    if (caller != collectModule) {
      _transferAmount(_token, _amount, _grantAddress, _voter);
    }

    /// @dev emit event for transfer
    emit Events.Voted(_token, _amount, _voter, _grantAddress, _projectId, _applicationIndex, msg.sender);
  }

  function _getContributionData(
    bytes memory data,
    address voter
  )
    internal
    view
    returns (
      address _token,
      uint256 _amount,
      address _grantAddress,
      bytes32 _projectId,
      uint256 _applicationIndex,
      address _voter
    )
  {
    if (voter == collectModule) {
      return abi.decode(data, (address, uint256, address, bytes32, uint256, address));
    }

    _voter = voter;

    (_token, _amount, _grantAddress, _projectId, _applicationIndex) = abi.decode(
      data,
      (address, uint256, address, bytes32, uint256)
    );
  }

  /**
   * @dev Transfer amount to the grant address
   *
   * This should be called by vote()
   *
   * @param token Address of the token to be tranfered
   * @param amount Amount to be tranfered
   * @param grantAddress Address of the receiver
   * @param voterAddress Address of the voter
   */
  function _transferAmount(address token, uint256 amount, address grantAddress, address voterAddress) internal {
    if (token == address(0)) {
      /// @dev native token transfer to grant address
      // slither-disable-next-line reentrancy-events
      AddressUpgradeable.sendValue(payable(grantAddress), amount);
    } else {
      /// @dev erc20 transfer to grant address
      // slither-disable-next-line arbitrary-send-erc20,reentrancy-events,
      SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(token), voterAddress, grantAddress, amount);
    }
  }
}
