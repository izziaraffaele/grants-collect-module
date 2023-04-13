// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library DataTypes {
  struct ProfilePublicationData {
    address roundAddress;
    bytes32 projectId;
    uint256 applicationIndex;
    address currency;
    uint96 currentCollects;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
  }

  struct ProfilePublicationInitData {
    address roundAddress;
    bytes32 projectId;
    uint256 applicationIndex;
    address currency;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
  }
}
