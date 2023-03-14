// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILensHub} from "@aave/lens-protocol/contracts/interfaces/ILensHub.sol";
import {ModuleBase} from "@aave/lens-protocol/contracts/core/modules/ModuleBase.sol";
import {FollowValidationModuleBase} from "@aave/lens-protocol/contracts/core/modules/FollowValidationModuleBase.sol";

import {LensErrors} from "./utils/Errors.sol";
import {IRoundImplementation} from "./interfaces/IRoundImplementation.sol";
// prettier-ignore
import {
  IGitcoinCollectModule,
  ProfilePublicationData,
  RoundApplicationData
} from "./interfaces/IGitcoinCollectModule.sol";

/**
 * @notice Lens collect module for Gitcoin grants rounds.
 *
 * @author Izzia Raffaele (https://github.com/izziaraffaele/grants-collect-module)
 */
contract GitcoinCollectModule is IGitcoinCollectModule, FollowValidationModuleBase {
  using SafeERC20 for IERC20;

  // --- Constants ---

  uint16 internal constant BPS_MAX = 10000;

  /// @notice round operator role
  bytes32 public constant ROUND_OPERATOR_ROLE = keccak256("ROUND_OPERATOR");

  // --- Data ---

  mapping(uint256 => mapping(uint256 => ProfilePublicationData)) internal dataByPublicationByProfile;
  mapping(address => mapping(uint256 => uint256)) internal amountByCollectNFT;

  // --- Core methods ---

  constructor(address hub) ModuleBase(hub) {
    // empty
  }

  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Encoded RoundApplicationData.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializePublicationCollectModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external onlyHub returns (bytes memory) {
    RoundApplicationData memory initData = abi.decode(data, (RoundApplicationData));

    if (initData.referralFee > BPS_MAX || initData.roundAddress == address(0) || initData.recipient == address(0)) {
      revert LensErrors.InitParamsInvalid();
    }

    // apply to the round
    IRoundImplementation(initData.roundAddress).applyToRound(bytes32(profileId), initData.applicationMetaPtr);

    // store publication data
    dataByPublicationByProfile[profileId][pubId] = ProfilePublicationData({
      roundAddress: initData.roundAddress,
      // Lens collect NFTs are initialized within the first collect
      // Calling ILensHub.getCollectNFT at this stage would return a zero-address
      collectToken: address(0),
      currency: initData.currency,
      currentCollects: 0,
      recipient: initData.recipient,
      referralFee: initData.referralFee,
      followerOnly: initData.followerOnly
    });

    return data;
  }

  /**
   * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
   * initialized with this module.
   *
   * @param profileId The token ID of the profile mapped to the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return The ProfilePublicationData struct mapped to that publication.
   */
  function getPublicationData(uint256 profileId, uint256 pubId) external view returns (ProfilePublicationData memory) {
    return dataByPublicationByProfile[profileId][pubId];
  }

  /**
   * @notice Returns the amount collected for a given collect NFT id attached to a given publication.
   *
   * @param profileId The token ID of the profile mapped to the publication to query.
   * @param pubId The publication ID of the publication to query.
   * @param collectTokenID The collect NFT ID of the publication to query.
   *
   * @return The amount collected for the given collect NFT ID
   */
  function getCollectNFTAmount(
    uint256 profileId,
    uint256 pubId,
    uint256 collectTokenID
  ) external view returns (uint256) {
    address collectNFT = dataByPublicationByProfile[profileId][pubId].collectToken;
    return amountByCollectNFT[collectNFT][collectTokenID];
  }

  /**
   * @notice Processes a collect action for a given publication, this can only be called by the hub.
   *
   * @dev Processes a collect by:
   *  1. Validating that collect action meets all needded criteria
   *  2. Processing the collect action either with or withour referral
   *  3. Casting a vote for the grant assigned to the publication
   *
   * @param referrerProfileId The LensHub profile token ID of the referrer's profile (different in case of mirrors).
   * @param collector The collector address.
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param data Arbitrary data __passed from the collector!__ to be decoded.
   */
  function processCollect(
    uint256 referrerProfileId,
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external onlyHub {
    _validateAndStoreCollect(referrerProfileId, collector, profileId, pubId, data);

    uint256 amount;

    if (referrerProfileId == profileId) {
      amount = _processCollect(collector, profileId, pubId, data);
    } else {
      amount = _processCollectWithReferral(referrerProfileId, collector, profileId, pubId, data);
    }
    _vote(profileId, pubId, amount, dataByPublicationByProfile[profileId][pubId].currentCollects);
  }

  /**
   * @notice Calculates and returns the collect fee of a publication.
   * @dev Amount to donate is decided by the collector.
   *
   * @param data Arbitrary data __passed from the collector!__ to the processCollect() function.
   *
   * @return The collect fee of the specified publication.
   */
  function calculateFee(uint256, uint256, bytes calldata data) public view virtual returns (uint256) {
    (, uint256 amount) = abi.decode(data, (address, uint256));
    return amount;
  }

  /**
   * @dev Validates the collect action by checking that:
   * 1) the collector is a follower (if enabled)
   *
   * This should be called during processCollect()
   *
   * @param collector The collector address.
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   */
  function _validateAndStoreCollect(
    uint256,
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) internal virtual {
    if (dataByPublicationByProfile[profileId][pubId].followerOnly) {
      _checkFollowValidity(profileId, collector);
    }

    if (dataByPublicationByProfile[profileId][pubId].collectToken == address(0)) {
      dataByPublicationByProfile[profileId][pubId].collectToken = ILensHub(HUB).getCollectNFT(profileId, pubId);
    }

    address collectNFT = dataByPublicationByProfile[profileId][pubId].collectToken;
    uint256 nextCollect = ++dataByPublicationByProfile[profileId][pubId].currentCollects;
    (, uint256 amount) = abi.decode(data, (address, uint256));

    amountByCollectNFT[collectNFT][nextCollect] = amount;
  }

  /**
   * @dev Internal processing of a collect:
   *  1. Calculation of fees
   *  2. Validation that fees are what collector expected
   *  3. Transfer of fees to recipient(-s) and treasury
   *
   * @param collector The address that will collect the post.
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param data Arbitrary data __passed from the collector!__ to be decoded.
   */
  function _processCollect(
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) internal returns (uint256) {
    uint256 amount = calculateFee(profileId, pubId, data);
    address currency = dataByPublicationByProfile[profileId][pubId].currency;
    _validateDataIsExpected(data, currency);

    // Send amount to all recipients
    _transferToRecipients(currency, collector, profileId, pubId, amount);

    return amount;
  }

  /**
   * @dev Internal processing of a collect with a referral(-s).
   *
   * Same as _processCollect, but also includes transfer to referral(-s):
   *  1. Calculation of fees
   *  2. Validation that fees are what collector expected
   *  3. Transfer of fees to recipient(-s), referral(-s) and treasury
   *
   * @param referrerProfileId The address of the referral.
   * @param collector The address that will collect the post.
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param data Arbitrary data __passed from the collector!__ to be decoded.
   */
  function _processCollectWithReferral(
    uint256 referrerProfileId,
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) internal returns (uint256) {
    uint256 amount = calculateFee(profileId, pubId, data);
    address currency = dataByPublicationByProfile[profileId][pubId].currency;
    _validateDataIsExpected(data, currency);

    uint256 adjustedAmount = _transferToReferrals(
      currency,
      referrerProfileId,
      collector,
      profileId,
      pubId,
      amount,
      data
    );

    _transferToRecipients(currency, collector, profileId, pubId, adjustedAmount);

    return adjustedAmount;
  }

  /**
   * @dev Encodes and cast vote for a grants round
   *
   * This should be called by processCollect()
   *
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param amount Vote amount
   * @param collectTokenId ID of the collect NFT for the current collect action
   */
  function _vote(uint256 profileId, uint256 pubId, uint256 amount, uint256 collectTokenId) internal {
    bytes[] memory encodedVotes = _toBytesArray(
      abi.encode(
        dataByPublicationByProfile[profileId][pubId].currency,
        amount,
        dataByPublicationByProfile[profileId][pubId].recipient,
        bytes32(profileId),
        bytes32(pubId),
        collectTokenId
      )
    );

    address roundAddress = dataByPublicationByProfile[profileId][pubId].roundAddress;
    IRoundImplementation(roundAddress).vote(encodedVotes);
  }

  /**
   * @dev Tranfers the fee to recipient(-s)
   *
   * Override this to add additional functionality (e.g. multiple recipients)
   *
   * @param currency Currency of the transaction
   * @param collector The address that collects the post (and pays the fee).
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param amount Amount to transfer to recipient(-s)
   */
  function _transferToRecipients(
    address currency,
    address collector,
    uint256 profileId,
    uint256 pubId,
    uint256 amount
  ) internal virtual {
    address recipient = dataByPublicationByProfile[profileId][pubId].recipient;

    if (amount > 0) {
      IERC20(currency).safeTransferFrom(collector, recipient, amount);
    }
  }

  /**
   * @dev Tranfers the part of fee to referral(-s)
   *
   * Override this to add additional functionality (e.g. multiple referrals)
   *
   * @param currency Currency of the transaction
   * @param referrerProfileId The address of the referral.
   * @param collector The address that collects the post (and pays the fee).
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param amount Amount of the fee
   */
  function _transferToReferrals(
    address currency,
    uint256 referrerProfileId,
    address collector,
    uint256 profileId,
    uint256 pubId,
    uint256 amount,
    bytes calldata
  ) internal virtual returns (uint256) {
    uint256 referralFee = dataByPublicationByProfile[profileId][pubId].referralFee;

    if (referralFee != 0) {
      uint256 referralAmount = (amount * referralFee) / BPS_MAX;
      if (referralAmount > 0) {
        // apply the referral fee to collector amount
        amount = amount - referralAmount;

        address referralRecipient = IERC721Enumerable(HUB).ownerOf(referrerProfileId);

        // Send referral fee in normal ERC20 tokens
        IERC20(currency).safeTransferFrom(collector, referralRecipient, referralAmount);
      }
    }

    // return the adjusted amount
    return amount;
  }

  function _validateDataIsExpected(bytes calldata data, address currency) internal pure virtual {
    (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
    if (decodedAmount == 0 || decodedCurrency != currency) revert LensErrors.ModuleDataMismatch();
  }

  function _toBytesArray(bytes memory n) internal pure returns (bytes[] memory) {
    bytes[] memory ret = new bytes[](1);
    ret[0] = n;
    return ret;
  }
}
