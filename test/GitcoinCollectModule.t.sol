// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./BaseSetup.sol";
import {GitcoinCollectModuleBase} from "./GitcoinCollectModule.base.sol";

/////////
// Publication Creation with GitcoinCollectModule
//
contract GitcoinCollectModule_Publication is GitcoinCollectModuleBase {
  uint256 immutable userProfileId;

  constructor() GitcoinCollectModuleBase() {
    userProfileId = hub.createProfile(
      LensDataTypes.CreateProfileData({
        to: me,
        handle: "user",
        imageURI: OTHER_MOCK_URI,
        followModule: address(0),
        followModuleInitData: "",
        followNFTURI: MOCK_FOLLOW_NFT_URI
      })
    );
  }

  function setUp() public {
    exampleInitData.roundAddress = address(round);
    exampleInitData.projectId = MOCK_PROJECT_ID;
    exampleInitData.applicationIndex = 1;
    exampleInitData.currency = address(currency);
    exampleInitData.referralFee = 0;
    exampleInitData.followerOnly = false;
    exampleInitData.recipient = me;
  }

  function hubPostWithRevert(bytes4 expectedError) public virtual {
    vm.expectRevert(expectedError);
    hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  // Negatives
  // function testCannotPostWithNonWhitelistedCurrency() public {
  //   exampleInitData.currency = address(0);
  //   hubPostWithRevert(LensErrors.InitParamsInvalid.selector);
  // }

  // We don't test for zero recipient here for two reasons:
  //  1) Allows burning tokens
  //  2) Inherited modules might not use the recipient field and leave it zero
  //
  function testCannotPostWithZeroAddressRecipient() public {
    exampleInitData.recipient = address(0);
    hubPostWithRevert(LensErrors.InitParamsInvalid.selector);
  }

  function testCannotPostWithZeroRoundAddress() public {
    exampleInitData.roundAddress = address(0);
    hubPostWithRevert(LensErrors.InitParamsInvalid.selector);
  }

  function testCannotPostWithReferralFeeGreaterThanMaxBPS() public {
    exampleInitData.referralFee = TREASURY_FEE_MAX_BPS + 1;
    hubPostWithRevert(LensErrors.InitParamsInvalid.selector);
  }

  function testCannotPostIfCalledFromNonHubAddress() public {
    vm.expectRevert(LensErrors.NotHub.selector);
    gitcoinCollectModule.initializePublicationCollectModule(userProfileId, 1, getEncodedInitData());
  }

  function testCannotPostWithWrongInitDataFormat() public {
    vm.expectRevert();
    hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: abi.encode(REFERRAL_FEE_BPS, true),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  // Scenarios
  function testCreatePublicationWithCorrectInitData() public {
    hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  function testCreatePublicationEmitsExpectedEvents() public {
    uint256 pubId = hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    assertEq(pubId, 1);
  }

  function testCreatePublicationApplyToRound() public {
    uint256 pubId = hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    assertEq(pubId, 1);
  }

  function testFuzzCreatePublicationWithDifferentInitData(uint16 referralFee, bool followerOnly) public virtual {
    referralFee = uint16(bound(referralFee, 0, TREASURY_FEE_MAX_BPS));

    DataTypes.ProfilePublicationInitData memory fuzzyInitData = DataTypes.ProfilePublicationInitData({
      roundAddress: address(round),
      projectId: MOCK_PROJECT_ID,
      applicationIndex: 1,
      currency: address(currency),
      referralFee: referralFee,
      followerOnly: followerOnly,
      recipient: me
    });

    hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: abi.encode(fuzzyInitData),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  function testFuzzFetchedPublicationDataShouldBeAccurate(uint16 referralFee, bool followerOnly) public virtual {
    referralFee = uint16(bound(referralFee, 0, TREASURY_FEE_MAX_BPS));

    DataTypes.ProfilePublicationInitData memory fuzzyInitData = DataTypes.ProfilePublicationInitData({
      roundAddress: address(round),
      projectId: MOCK_PROJECT_ID,
      applicationIndex: 1,
      currency: address(currency),
      referralFee: referralFee,
      followerOnly: followerOnly,
      recipient: me
    });

    uint256 pubId = hub.post(
      LensDataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: abi.encode(fuzzyInitData),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
    assert(pubId > 0);

    DataTypes.ProfilePublicationData memory fetchedData = gitcoinCollectModule.getPublicationData(userProfileId, pubId);
    assertEq(fetchedData.roundAddress, fuzzyInitData.roundAddress);
    assertEq(fetchedData.currency, fuzzyInitData.currency);
    assertEq(fetchedData.referralFee, fuzzyInitData.referralFee);
    assertEq(fetchedData.followerOnly, fuzzyInitData.followerOnly);
    assertEq(fetchedData.recipient, fuzzyInitData.recipient);
  }
}

//////////////
// Collect with GitcoinCollectModule
//
contract GitcoinCollectModule_Collect is GitcoinCollectModuleBase {
  uint256 immutable publisherProfileId;
  uint256 immutable userProfileId;

  uint256 pubId;

  constructor() GitcoinCollectModuleBase() {
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
  }

  function setUp() public virtual {
    exampleInitData.roundAddress = address(round);
    exampleInitData.projectId = MOCK_PROJECT_ID;
    exampleInitData.applicationIndex = 1;
    exampleInitData.currency = address(currency);
    exampleInitData.referralFee = 0;
    exampleInitData.followerOnly = false;
    exampleInitData.recipient = me;

    vm.prank(publisher);
    pubId = hub.post(
      LensDataTypes.PostData({
        profileId: publisherProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    currency.mint(user, type(uint256).max);
    vm.prank(user);
    currency.approve(collectModuleAddr, type(uint256).max);
  }

  // Negatives

  function testCannotCollectIfCalledFromNonHubAddress() public {
    vm.expectRevert(LensErrors.NotHub.selector);
    gitcoinCollectModule.processCollect(
      publisherProfileId,
      me,
      publisherProfileId,
      pubId,
      abi.encode(exampleInitData.currency, 1 ether)
    );
  }

  function testCannotCollectNonExistentPublication() public {
    vm.prank(user);
    vm.expectRevert(LensErrors.PublicationDoesNotExist.selector);
    hub.collect(publisherProfileId, pubId + 1, abi.encode(exampleInitData.currency, 1 ether));
  }

  function testCannotCollectPassingZeroAmountInData() public {
    vm.prank(user);
    vm.expectRevert(LensErrors.ModuleDataMismatch.selector);
    hub.collect(publisherProfileId, pubId, abi.encode(exampleInitData.currency, 0));
  }

  function testCannotCollectPassingWrongCurrencyInData() public {
    vm.prank(user);
    vm.expectRevert(LensErrors.ModuleDataMismatch.selector);
    hub.collect(publisherProfileId, pubId, abi.encode(address(0xdead), 1 ether));
  }

  function testCannotCollectWithoutEnoughApproval() public {
    vm.startPrank(user);
    currency.approve(collectModuleAddr, 0);
    assert(currency.allowance(user, collectModuleAddr) < 1 ether);
    vm.expectRevert("ERC20: insufficient allowance");
    hub.collect(publisherProfileId, pubId, abi.encode(exampleInitData.currency, 1 ether));
    vm.stopPrank();
  }

  function testCannotCollectWithoutEnoughBalance() public {
    vm.startPrank(user);
    currency.transfer(address(1), currency.balanceOf(user));
    assertEq(currency.balanceOf(user), 0);
    assert(currency.allowance(user, collectModuleAddr) >= 1 ether);
    vm.expectRevert("ERC20: transfer amount exceeds balance");
    hub.collect(publisherProfileId, pubId, abi.encode(exampleInitData.currency, 1 ether));
    vm.stopPrank();
  }

  function hubPost() public virtual returns (uint256) {
    vm.prank(publisher);
    uint256 newPubId = hub.post(
      LensDataTypes.PostData({
        profileId: publisherProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
    return newPubId;
  }

  function testCannotCollectIfNotAFollower() public {
    exampleInitData.followerOnly = true;
    uint256 secondPubId = hubPost();
    vm.startPrank(user);
    vm.expectRevert(LensErrors.FollowInvalid.selector);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
    vm.stopPrank();
  }

  //Scenarios

  function testCanCollectIfAllConditionsAreMet() public {
    uint256 secondPubId = hubPost();
    vm.startPrank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
    vm.stopPrank();
  }

  function testCollectEmitsCollectedEvent() public {
    uint256 secondPubId = hubPost();

    vm.expectEmit(true, true, true, false);
    emit Events.Voted(
      exampleInitData.currency,
      1 ether,
      user,
      exampleInitData.recipient,
      MOCK_PROJECT_ID,
      1,
      address(round)
    );

    vm.prank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
  }

  function testCollectEmitsVotedEvent() public {
    uint256 secondPubId = hubPost();

    vm.expectEmit(true, true, true, false);
    emit Events.Voted(
      exampleInitData.currency,
      1 ether,
      user,
      exampleInitData.recipient,
      MOCK_PROJECT_ID,
      1,
      address(round)
    );

    vm.prank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
  }
}
