// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../BaseSetup.sol";
import {MockRoundImplementation} from "../mocks/MockRoundImplementation.sol";
import {LensCollectVotingStrategyImplementationBase} from "./LensCollectVotingStrategyImplementation.base.sol";
import {Events} from "../../src/utils/Events.sol";
import {Errors, LensErrors} from "../../src/utils/Errors.sol";
import {IGitcoinCollectModule} from "../../src/interfaces/IGitcoinCollectModule.sol";
import {LensCollectVotingStrategyImplementation} from "../../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";

contract LensCollectVotingStrategyImplementation_Init is LensCollectVotingStrategyImplementationBase {
  constructor() LensCollectVotingStrategyImplementationBase() {
    // empty
  }

  function testCannotInitTwice() public virtual {
    vm.prank(roundImplementation);
    vm.expectRevert(LensErrors.Initialized.selector);
    LensCollectVotingStrategyImplementation(votingStrategy).init();
  }

  function testInitShouldSetRoundAddress() public virtual {
    assertEq(LensCollectVotingStrategyImplementation(votingStrategy).roundAddress(), roundImplementation);
  }

  function testCannotInitializeTwice() public virtual {
    vm.prank(deployer);
    vm.expectRevert(LensErrors.Initialized.selector);
    LensCollectVotingStrategyImplementation(votingStrategy).init();
  }

  function testInitializeShouldSetCollectModule() public virtual {
    assertEq(LensCollectVotingStrategyImplementation(votingStrategy).collectModule(), gitcoinCollectModule);
  }
}

contract LensCollectVotingStrategyImplementation_Vote is LensCollectVotingStrategyImplementationBase {
  constructor() LensCollectVotingStrategyImplementationBase() {
    currency.mint(user, 1 ether);
    vm.prank(user);
    currency.approve(votingStrategy, type(uint256).max);
  }

  function setUp() public {
    exampleVoteData.token = exampleInitData.currency;
    exampleVoteData.amount = 1 ether;
    exampleVoteData.grantAddress = publisher;
    exampleVoteData.projectId = bytes32("1");
  }

  function testCannotVoteIfCalledFromNonRound() public virtual {
    vm.expectRevert(Errors.NotRoundContract.selector);
    LensCollectVotingStrategyImplementation(votingStrategy).vote(getEncodedVotes(), user);
  }

  function testCannotVoteWithoutEnoughApproval() public virtual {
    vm.startPrank(user);
    currency.approve(votingStrategy, 0);
    assert(currency.allowance(user, votingStrategy) < 1 ether);
    vm.expectRevert("ERC20: insufficient allowance");
    MockRoundImplementation(roundImplementation).vote(getEncodedVotes());
    vm.stopPrank();
  }

  function testCannotVoteWithoutEnoughBalance() public virtual {
    vm.startPrank(user);
    currency.transfer(address(1), currency.balanceOf(user));
    assertEq(currency.balanceOf(user), 0);
    assert(currency.allowance(user, votingStrategy) >= 1 ether);
    vm.expectRevert("ERC20: transfer amount exceeds balance");
    MockRoundImplementation(roundImplementation).vote(getEncodedVotes());
    vm.stopPrank();
  }

  function testCannotVoteWithoutEnoughEthBalance() public virtual {
    exampleVoteData.token = address(0);

    assertEq(exampleVoteData.grantAddress.balance, 0);
    assertEq(user.balance, 0);

    vm.prank(user);
    vm.expectRevert();
    MockRoundImplementation(roundImplementation).vote(getEncodedVotes());
  }

  function testVoteTransferAmountToGrantAddress() public virtual {
    uint256 balanceBefore = currency.balanceOf(user);

    assert(balanceBefore >= 1 ether);
    assertEq(currency.balanceOf(exampleVoteData.grantAddress), 0);

    vm.prank(user);
    MockRoundImplementation(roundImplementation).vote(getEncodedVotes());
    assertEq(currency.balanceOf(exampleVoteData.grantAddress), 1 ether);
    assertEq(currency.balanceOf(user), balanceBefore - 1 ether);
  }

  function testVoteTransferEthToGrantAddress() public virtual {
    exampleVoteData.token = address(0);
    vm.deal(user, 100 ether);

    assertEq(exampleVoteData.grantAddress.balance, 0);
    assertEq(user.balance, 100 ether);

    vm.prank(user);
    MockRoundImplementation(roundImplementation).vote{value: 1 ether}(getEncodedVotes());

    assertEq(exampleVoteData.grantAddress.balance, 1 ether);
    assertEq(user.balance, 99 ether);
  }
}

contract LensCollectVotingStrategyImplementation_LensVote is LensCollectVotingStrategyImplementationBase {
  uint256 immutable publisherProfileId;

  uint256 immutable userProfileId;

  uint256 pubId;

  constructor() LensCollectVotingStrategyImplementationBase() {
    exampleInitData.recipient = publisher;
    publisherProfileId = hub.createProfile(
      DataTypes.CreateProfileData({
        to: publisher,
        handle: "pub",
        imageURI: OTHER_MOCK_URI,
        followModule: address(0),
        followModuleInitData: "",
        followNFTURI: MOCK_FOLLOW_NFT_URI
      })
    );

    userProfileId = hub.createProfile(
      DataTypes.CreateProfileData({
        to: user,
        handle: "user",
        imageURI: OTHER_MOCK_URI,
        followModule: address(0),
        followModuleInitData: "",
        followNFTURI: MOCK_FOLLOW_NFT_URI
      })
    );

    vm.prank(publisher);
    pubId = hub.post(
      DataTypes.PostData({
        profileId: publisherProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    currency.mint(user, 1 ether);
    vm.prank(user);
    currency.approve(gitcoinCollectModule, type(uint256).max);
  }

  function setUp() public virtual {
    exampleVoteData.token = exampleInitData.currency;
    exampleVoteData.amount = 1 ether;
    exampleVoteData.grantAddress = publisher;
    exampleVoteData.projectId = bytes32(publisherProfileId);
    exampleVoteData.pubId = bytes32(pubId);
    exampleVoteData.collectTokenId = 1;

    vm.mockCall(
      gitcoinCollectModule,
      abi.encodeWithSelector(IGitcoinCollectModule.getCollectNFTAmount.selector),
      abi.encode(exampleVoteData.amount)
    );
  }

  function roundVote() public {
    MockRoundImplementation(roundImplementation).vote(getEncodedVotes());
  }

  function hubVote() public {
    hub.collect(publisherProfileId, pubId, abi.encode(exampleInitData.currency, 1 ether));
  }

  function testCannotVoteTwiceWithSameNFT() public virtual {
    vm.startPrank(user);
    hubVote();
    vm.expectRevert(Errors.VoteCasted.selector);
    roundVote();
    vm.stopPrank();
  }

  function testCannotVoteWithNonExistingNFT() public virtual {
    vm.prank(user);
    vm.expectRevert(Errors.VoteInvalid.selector);
    roundVote();
  }

  function testCannotVoteWithNonExistingNFTId() public virtual {
    vm.prank(user);
    hubVote();

    exampleVoteData.collectTokenId = 2;

    vm.prank(user);
    vm.expectRevert("ERC721: owner query for nonexistent token");
    roundVote();
  }

  function testCannotVoteWithInvalidAmount() public virtual {
    // mock the vote call to prevent calls from hub
    vm.mockCall(roundImplementation, abi.encodeWithSelector(MockRoundImplementation.vote.selector), abi.encode());

    vm.prank(user);
    hubVote();

    exampleVoteData.amount = 100 ether;

    // clear the mock so that we can call the round implementation ourself
    vm.clearMockedCalls();

    vm.expectRevert(Errors.VoteInvalid.selector);
    vm.prank(user);
    roundVote();
  }

  function testCannotVoteWithInvalidToken() public virtual {
    // mock the vote call to prevent calls from hub
    vm.mockCall(roundImplementation, abi.encodeWithSelector(MockRoundImplementation.vote.selector), abi.encode());

    vm.prank(user);
    hubVote();

    exampleVoteData.token = address(0xdead);

    // clear the mock so that we can call the round implementation ourself
    vm.clearMockedCalls();

    vm.expectRevert(Errors.VoteInvalid.selector);
    vm.prank(user);
    roundVote();
  }

  function testVoteEmitsExpectedEvents() public virtual {
    vm.expectEmit(true, true, true, true, votingStrategy);

    emit Events.Voted(
      exampleVoteData.token,
      exampleVoteData.amount,
      user,
      exampleVoteData.grantAddress,
      exampleVoteData.projectId,
      roundImplementation
    );

    vm.prank(user);
    hubVote();
  }
}
