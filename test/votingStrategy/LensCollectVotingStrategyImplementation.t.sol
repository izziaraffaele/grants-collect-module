// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../BaseSetup.sol";

import {LensCollectVotingStrategyImplementationBase} from "./LensCollectVotingStrategyImplementation.base.sol";
import {LensCollectVotingStrategyImplementation} from "../../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";

contract LensCollectVotingStrategyImplementation_Init is LensCollectVotingStrategyImplementationBase {
  constructor() LensCollectVotingStrategyImplementationBase() {
    // empty
  }

  function testCannotInitTwice() public virtual {
    vm.prank(address(round));
    vm.expectRevert(Errors.Initialized.selector);
    votingStrategy.init();
  }

  function testInitShouldSetRoundAddress() public virtual {
    assertEq(votingStrategy.roundAddress(), address(round));
  }

  function testCannotInitializeTwice() public virtual {
    vm.prank(deployer);
    vm.expectRevert();
    votingStrategy.initialize(collectModuleAddr);
  }

  function testInitializeShouldSetCollectModule() public virtual {
    assertEq(votingStrategy.collectModule(), collectModuleAddr);
  }
}

contract LensCollectVotingStrategyImplementation_Vote is LensCollectVotingStrategyImplementationBase {
  constructor() LensCollectVotingStrategyImplementationBase() {
    currency.mint(user, 1 ether);

    vm.prank(user);
    currency.approve(address(votingStrategy), type(uint256).max);
  }

  function setUp() public {
    exampleVoteData.token = address(currency);
    exampleVoteData.amount = 1 ether;
    exampleVoteData.grantAddress = publisher;
    exampleVoteData.projectId = MOCK_PROJECT_ID;
  }

  function testCannotVoteWhenCallerNotRoundContractOrModule(address caller) public virtual {
    vm.assume(caller != collectModuleAddr && caller != address(round));
    vm.prank(caller);
    vm.expectRevert(Errors.NotRoundContractOrModule.selector);
    votingStrategy.vote(getEncodedVoteArrayData(), user);
  }

  function testCannotVoteWithoutEnoughApproval() public virtual {
    currency.mint(userTwo, 1 ether);

    vm.startPrank(userTwo);
    vm.expectRevert("ERC20: insufficient allowance");
    round.vote(getEncodedVoteArrayData());
    vm.stopPrank();
  }

  function testCannotVoteWithoutEnoughBalance() public virtual {
    vm.startPrank(userTwo);
    currency.approve(address(votingStrategy), type(uint256).max);
    vm.expectRevert("ERC20: transfer amount exceeds balance");
    round.vote(getEncodedVoteArrayData());
    vm.stopPrank();
  }

  function testCannotVoteWithoutEnoughEthBalance() public virtual {
    exampleVoteData.token = address(0);

    vm.prank(user);
    vm.expectRevert("Address: insufficient balance");
    round.vote(getEncodedVoteArrayData());
  }

  function testVoteTransferAmountToGrantAddress() public virtual {
    vm.prank(user);
    round.vote(getEncodedVoteArrayData());
    assertEq(currency.balanceOf(exampleVoteData.grantAddress), exampleVoteData.amount);
    assertEq(currency.balanceOf(user), 0);
  }

  function testVoteTransferEthToGrantAddress() public {
    exampleVoteData.token = address(0);
    vm.deal(user, exampleVoteData.amount);

    vm.prank(user);
    round.vote{value: exampleVoteData.amount}(getEncodedVoteArrayData());

    assertEq(exampleVoteData.grantAddress.balance, exampleVoteData.amount);
    assertEq(user.balance, 0);
  }
}

contract LensCollectVotingStrategyImplementation_LensVote is LensCollectVotingStrategyImplementationBase {
  uint256 immutable publisherProfileId;

  uint256 immutable userProfileId;

  uint256 pubId;

  DataTypes.ProfilePublicationInitData exampleInitData;

  constructor() LensCollectVotingStrategyImplementationBase() {
    publisherProfileId = hub.createProfile(
      LensDataTypes.CreateProfileData({
        to: publisher,
        handle: "pub",
        imageURI: OTHER_MOCK_URI,
        followModule: address(0),
        followModuleInitData: "",
        followNFTURI: MOCK_FOLLOW_NFT_URI
      })
    );

    userProfileId = hub.createProfile(
      LensDataTypes.CreateProfileData({
        to: user,
        handle: "user",
        imageURI: OTHER_MOCK_URI,
        followModule: address(0),
        followModuleInitData: "",
        followNFTURI: MOCK_FOLLOW_NFT_URI
      })
    );

    exampleInitData = DataTypes.ProfilePublicationInitData({
      roundAddress: address(round),
      projectId: MOCK_PROJECT_ID,
      applicationIndex: 1,
      currency: address(currency),
      referralFee: 0,
      followerOnly: false,
      recipient: me
    });

    vm.prank(publisher);
    pubId = hub.post(
      LensDataTypes.PostData({
        profileId: publisherProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: abi.encode(exampleInitData),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    currency.mint(user, 1 ether);
    vm.prank(user);
    currency.approve(collectModuleAddr, type(uint256).max);
  }

  function setUp() public virtual {
    exampleVoteData.token = exampleInitData.currency;
    exampleVoteData.amount = 1 ether;
    exampleVoteData.grantAddress = exampleInitData.recipient;
    exampleVoteData.projectId = exampleInitData.projectId;
    exampleVoteData.applicationIndex = exampleInitData.applicationIndex;
  }

  function hubVote() public {
    hub.collect(publisherProfileId, pubId, abi.encode(exampleVoteData.token, exampleVoteData.amount));
  }

  function testVoteEmitsExpectedEvents() public {
    vm.expectEmit(true, true, true, true, address(votingStrategy));

    emit Events.Voted(
      exampleVoteData.token,
      exampleVoteData.amount,
      user,
      exampleVoteData.grantAddress,
      exampleVoteData.projectId,
      exampleVoteData.applicationIndex,
      address(round)
    );

    vm.prank(user);
    hubVote();
  }
}
