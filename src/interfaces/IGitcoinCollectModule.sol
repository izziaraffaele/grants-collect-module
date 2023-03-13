// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {ICollectModule} from "@aave/lens-protocol/contracts/interfaces/ICollectModule.sol";
import {MetaPtr} from "../utils/MetaPtr.sol";

struct ProfilePublicationData {
  address roundAddress;
  address collectToken;
  address currency;
  uint96 currentCollects;
  address recipient;
  uint16 referralFee;
  bool followerOnly;
}

struct RoundApplicationData {
  address roundAddress;
  address currency;
  address recipient;
  uint16 referralFee;
  bool followerOnly;
  MetaPtr applicationMetaPtr;
}

interface IGitcoinCollectModule is ICollectModule {
  function getCollectNFTAmount(
    uint256 profileId,
    uint256 pubId,
    uint256 collectTokenId
  ) external view returns (uint256);

  function getPublicationData(uint256 profileId, uint256 pubId) external view returns (ProfilePublicationData memory);
}
