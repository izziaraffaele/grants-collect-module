// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./GitcoinCollectModule.base.sol";
import "../src/interfaces/IGitcoinCollectModule.sol";
import "../src/utils/MetaPtr.sol";
import "../src/GitcoinCollectModule.sol";

/////////
// Publication Creation with GitcoinCollectModule
//
contract GitcoinCollectModule_Publication is GitcoinCollectModuleBase {
  uint256 immutable userProfileId;

  constructor() GitcoinCollectModuleBase() {
    userProfileId = hub.createProfile(
      DataTypes.CreateProfileData({
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
    exampleInitData.roundAddress = roundImplementation;
    exampleInitData.currency = address(currency);
    exampleInitData.referralFee = 0;
    exampleInitData.followerOnly = false;
    exampleInitData.applicationMetaPtr = exampleApplicationMetaPtr;
    exampleInitData.recipient = me;
  }

  function hubPostWithRevert(bytes4 expectedError) public virtual {
    vm.expectRevert(expectedError);
    hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
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
    GitcoinCollectModule(gitcoinCollectModule).initializePublicationCollectModule(
      userProfileId,
      1,
      getEncodedInitData()
    );
  }

  function testCannotPostWithWrongInitDataFormat() public {
    vm.expectRevert();
    hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: abi.encode(REFERRAL_FEE_BPS, true),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  // Scenarios
  function testCreatePublicationWithCorrectInitData() public {
    hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  function testCreatePublicationEmitsExpectedEvents() public {
    uint256 pubId = hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    assertEq(pubId, 1);
  }

  function testCreatePublicationApplyToRound() public {
    vm.expectCall(
      roundImplementation,
      abi.encodeWithSelector(MockRoundImplementation.applyToRound.selector, bytes32(userProfileId))
    );

    uint256 pubId = hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    assertEq(pubId, 1);
  }

  function testFuzzCreatePublicationWithDifferentInitData(uint16 referralFee, bool followerOnly) public virtual {
    referralFee = uint16(bound(referralFee, 0, TREASURY_FEE_MAX_BPS));

    RoundApplicationData memory fuzzyInitData = RoundApplicationData({
      roundAddress: roundImplementation,
      currency: address(currency),
      referralFee: referralFee,
      followerOnly: followerOnly,
      applicationMetaPtr: exampleApplicationMetaPtr,
      recipient: me
    });

    hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: abi.encode(fuzzyInitData),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
  }

  function testFuzzFetchedPublicationDataShouldBeAccurate(uint16 referralFee, bool followerOnly) public virtual {
    referralFee = uint16(bound(referralFee, 0, TREASURY_FEE_MAX_BPS));

    RoundApplicationData memory fuzzyInitData = RoundApplicationData({
      roundAddress: roundImplementation,
      currency: address(currency),
      referralFee: referralFee,
      followerOnly: followerOnly,
      applicationMetaPtr: exampleApplicationMetaPtr,
      recipient: me
    });

    uint256 pubId = hub.post(
      DataTypes.PostData({
        profileId: userProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
        collectModuleInitData: abi.encode(fuzzyInitData),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );
    assert(pubId > 0);

    ProfilePublicationData memory fetchedData = GitcoinCollectModule(gitcoinCollectModule).getPublicationData(
      userProfileId,
      pubId
    );
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
  }

  function setUp() public virtual {
    exampleInitData.roundAddress = roundImplementation;
    exampleInitData.currency = address(currency);
    exampleInitData.referralFee = 0;
    exampleInitData.followerOnly = false;
    exampleInitData.applicationMetaPtr = exampleApplicationMetaPtr;
    exampleInitData.recipient = me;

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

    currency.mint(user, type(uint256).max);
    vm.prank(user);
    currency.approve(gitcoinCollectModule, type(uint256).max);
  }

  // Negatives

  function testCannotCollectIfCalledFromNonHubAddress() public {
    vm.expectRevert(LensErrors.NotHub.selector);
    GitcoinCollectModule(gitcoinCollectModule).processCollect(
      publisherProfileId,
      me,
      publisherProfileId,
      pubId,
      abi.encode(address(currency), 1 ether)
    );
  }

  function testCannotCollectNonExistentPublication() public {
    vm.prank(user);
    vm.expectRevert(LensErrors.PublicationDoesNotExist.selector);
    hub.collect(publisherProfileId, pubId + 1, abi.encode(address(currency), 1 ether));
  }

  function testCannotCollectPassingZeroAmountInData() public {
    vm.prank(user);
    vm.expectRevert(LensErrors.ModuleDataMismatch.selector);
    hub.collect(publisherProfileId, pubId, abi.encode(address(currency), 0));
  }

  function testCannotCollectWithoutEnoughApproval() public {
    vm.startPrank(user);
    currency.approve(gitcoinCollectModule, 0);
    assert(currency.allowance(user, gitcoinCollectModule) < 1 ether);
    vm.expectRevert("ERC20: insufficient allowance");
    hub.collect(publisherProfileId, pubId, abi.encode(address(currency), 1 ether));
    vm.stopPrank();
  }

  function testCannotCollectWithoutEnoughBalance() public {
    vm.startPrank(user);
    currency.transfer(address(1), currency.balanceOf(user));
    assertEq(currency.balanceOf(user), 0);
    assert(currency.allowance(user, gitcoinCollectModule) >= 1 ether);
    vm.expectRevert("ERC20: transfer amount exceeds balance");
    hub.collect(publisherProfileId, pubId, abi.encode(address(currency), 1 ether));
    vm.stopPrank();
  }

  function hubPost() public virtual returns (uint256) {
    vm.prank(publisher);
    uint256 newPubId = hub.post(
      DataTypes.PostData({
        profileId: publisherProfileId,
        contentURI: MOCK_URI,
        collectModule: gitcoinCollectModule,
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
    hub.collect(publisherProfileId, secondPubId, abi.encode(address(currency), 1 ether));
    vm.stopPrank();
  }

  //Scenarios

  function testCanCollectIfAllConditionsAreMet() public {
    uint256 secondPubId = hubPost();
    vm.startPrank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(address(currency), 1 ether));
    vm.stopPrank();
  }

  // function testProperEventsAreEmittedAfterCollect() public {
  //   uint256 secondPubId = hubPost();
  //   vm.startPrank(user);

  //   vm.expectEmit(true, true, true, false);
  //   emit Events.Collected(user, publisherProfileId, secondPubId, publisherProfileId, secondPubId, "", block.timestamp);
  //   hub.collect(publisherProfileId, secondPubId, abi.encode(address(currency), 1 ether));

  //   vm.stopPrank();
  // }

  function testFetchedCollectDataShouldBeAccurate() public virtual {
    uint256 secondPubId = hubPost();

    vm.prank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));

    CollectNFTData memory fetchedData = GitcoinCollectModule(gitcoinCollectModule).getCollectData(
      publisherProfileId,
      secondPubId,
      1
    );

    assertEq(fetchedData.amount, 1 ether);
    assertEq(fetchedData.currency, exampleInitData.currency);
  }
}
