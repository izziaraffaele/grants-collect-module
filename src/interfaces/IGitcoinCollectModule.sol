// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {ICollectModule} from "@aave/lens-protocol/contracts/interfaces/ICollectModule.sol";
import {MetaPtr} from "../utils/MetaPtr.sol";

struct ProfilePublicationData {
  address roundAddress;
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

struct CollectNFTData {
  uint256 amount;
  address currency;
}

interface IGitcoinCollectModule is ICollectModule {
  function getPublicationData(uint256 profileId, uint256 pubId) external view returns (ProfilePublicationData memory);

  function getCollectData(
    uint256 profileId,
    uint256 pubId,
    uint256 collectIndex
  ) external view returns (CollectNFTData memory);
}
