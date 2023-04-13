// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ICollectModule} from "@aave/lens-protocol/contracts/interfaces/ICollectModule.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IGitcoinCollectModule is ICollectModule {
  function getPublicationData(
    uint256 profileId,
    uint256 pubId
  ) external view returns (DataTypes.ProfilePublicationData memory);
}
