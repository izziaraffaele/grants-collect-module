// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// prettier-ignore
import {
  SafeERC20Upgradeable,
  IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {ILensCollectVotingStrategy} from "../interfaces/ILensCollectVotingStrategy.sol";
import {IGitcoinCollectModule, ProfilePublicationData} from "../interfaces/IGitcoinCollectModule.sol";
import {Errors, LensErrors} from "../utils/Errors.sol";
import {Events} from "../utils/Events.sol";

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

  /// @notice Mapping to store casted votes by collect NFT
  mapping(address => mapping(uint256 => uint256)) internal votesByCollectNFT;

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
      revert LensErrors.Initialized();
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
      revert LensErrors.Initialized();
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
    /// @dev iterate over multiple donations and transfer funds
    for (uint256 i = 0; i < encodedVotes.length; i++) {
      /// @dev decode encoded vote
      (
        address _token,
        uint256 _amount,
        address _grantAddress,
        bytes32 _projectId,
        bytes32 _pubId,
        uint256 _collectTokenId
      ) = abi.decode(encodedVotes[i], (address, uint256, address, bytes32, bytes32, uint256));

      if (_collectTokenId != 0 && uint256(_pubId) != 0) {
        _voteWithCollect(_token, _amount, _grantAddress, uint256(_projectId), uint256(_pubId), _collectTokenId);
      } else {
        _voteWithTransfer(_token, _amount, voterAddress, _grantAddress, _projectId);
      }
    }
  }

  function _voteWithCollect(
    address token,
    uint256 amount,
    address grantAddress,
    uint256 profileId,
    uint256 pubId,
    uint256 collectTokenId
  ) internal {
    _validateAndStoreCollect(token, amount, profileId, pubId, collectTokenId);

    ProfilePublicationData memory pubData = IGitcoinCollectModule(collectModule).getPublicationData(profileId, pubId);
    address voterAddress = IERC721(pubData.collectToken).ownerOf(collectTokenId);

    /// @dev emit event for transfer
    emit Events.Voted(token, amount, voterAddress, grantAddress, bytes32(profileId), msg.sender);
  }

  function _voteWithTransfer(
    address token,
    uint256 amount,
    address voterAddress,
    address grantAddress,
    bytes32 projectId
  ) internal {
    _transferAmount(token, amount, grantAddress, voterAddress);

    /// @dev emit event for transfer
    emit Events.Voted(token, amount, voterAddress, grantAddress, projectId, msg.sender);
  }

  /**
   * @dev Validates and store a vote casted via Lens collect module
   *
   * This should be called by vote()
   *
   * @param token Address of the token used by the collector (__passed from the collector!__)
   * @param amount Collected amount (__passed from the collector!__)
   * @param profileId Lens profile id of the grant
   * @param pubId Lens publication id of the grant
   * @param collectTokenId Collect nft index assigned to this vote
   */
  function _validateAndStoreCollect(
    address token,
    uint256 amount,
    uint256 profileId,
    uint256 pubId,
    uint256 collectTokenId
  ) internal {
    // validate data passed from the collector
    ProfilePublicationData memory pubData = IGitcoinCollectModule(collectModule).getPublicationData(profileId, pubId);

    if (pubData.collectToken == address(0)) {
      revert Errors.VoteInvalid();
    }

    // prevent from casting multiple votes
    if (votesByCollectNFT[pubData.collectToken][collectTokenId] > 0) {
      revert Errors.VoteCasted();
    }

    uint256 collectedAmount = IGitcoinCollectModule(collectModule).getCollectNFTAmount(
      profileId,
      pubId,
      collectTokenId
    );

    if (collectedAmount != amount || pubData.currency != token) {
      revert Errors.VoteInvalid();
    }

    // register the vote to prevent double counting
    votesByCollectNFT[pubData.collectToken][collectTokenId] = collectedAmount;
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
