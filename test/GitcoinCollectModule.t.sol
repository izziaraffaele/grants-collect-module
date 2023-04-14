// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./BaseSetup.sol";
import "./helpers/TestHelpers.sol";
import {GitcoinCollectModuleBase} from "./GitcoinCollectModule.base.sol";

uint16 constant BPS_MAX = 10000;

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

  function testCannotPostWhenNotHub() public {
    vm.expectRevert(LensErrors.NotHub.selector);
    gitcoinCollectModule.initializePublicationCollectModule(userProfileId, 1, getEncodedInitData());
  }

  function testCannotPostWithPendingApplication() public {
    ++exampleInitData.applicationIndex;

    vm.expectRevert(Errors.InitParamsInvalid.selector);
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

  function testCreatePublicationEmitsExpectedEvents() public {
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

    currency.mint(user, 1 ether);

    vm.prank(user);
    currency.approve(collectModuleAddr, type(uint256).max);
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
    currency.mint(userTwo, 1 ether);

    vm.prank(userTwo);
    vm.expectRevert("ERC20: insufficient allowance");
    hub.collect(publisherProfileId, pubId, abi.encode(exampleInitData.currency, 1 ether));
  }

  function testCannotCollectWithoutEnoughBalance() public {
    vm.startPrank(userTwo);
    currency.approve(collectModuleAddr, 1 ether);

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
    vm.prank(user);
    vm.expectRevert(LensErrors.FollowInvalid.selector);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
  }

  //Scenarios

  function testCanCollectIfAllConditionsAreMet() public {
    uint256 secondPubId = hubPost();
    vm.prank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
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
      exampleInitData.projectId,
      exampleInitData.applicationIndex,
      address(round)
    );

    vm.prank(user);
    hub.collect(publisherProfileId, secondPubId, abi.encode(exampleInitData.currency, 1 ether));
  }

  function testCurrentCollectsIncreaseProperlyWhenCollecting() public virtual {
    uint256 secondPubId = hubPost();
    vm.startPrank(user);

    DataTypes.ProfilePublicationData memory fetchedData = gitcoinCollectModule.getPublicationData(
      publisherProfileId,
      secondPubId
    );
    assertEq(fetchedData.currentCollects, 0);

    for (uint256 collects = 1; collects < 5; collects++) {
      currency.mint(user, 1 ether);
      hub.collect(publisherProfileId, secondPubId, abi.encode(address(currency), 1 ether));
      fetchedData = gitcoinCollectModule.getPublicationData(publisherProfileId, secondPubId);
      assertEq(fetchedData.currentCollects, collects);
    }
    vm.stopPrank();
  }
}

contract GitcoinCollectModule_Mirror is GitcoinCollectModuleBase, GitcoinCollectModule_Collect {
  uint256 immutable userTwoProfileId;
  uint256 origPubId;

  constructor() GitcoinCollectModule_Collect() {
    userTwoProfileId = hub.createProfile(
      LensDataTypes.CreateProfileData({
        to: userTwo,
        handle: "usertwo.lens",
        imageURI: OTHER_MOCK_URI,
        followModule: address(0),
        followModuleInitData: "",
        followNFTURI: MOCK_FOLLOW_NFT_URI
      })
    );
  }

  function setUp() public override {
    exampleInitData.roundAddress = address(round);
    exampleInitData.projectId = MOCK_PROJECT_ID;
    exampleInitData.applicationIndex = 1;
    exampleInitData.currency = address(currency);
    exampleInitData.referralFee = 0;
    exampleInitData.followerOnly = false;
    exampleInitData.recipient = me;

    vm.prank(userTwo);
    origPubId = hub.post(
      LensDataTypes.PostData({
        profileId: userTwoProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    vm.prank(publisher);
    pubId = hub.mirror(
      LensDataTypes.MirrorData({
        profileId: publisherProfileId,
        profileIdPointed: userTwoProfileId,
        pubIdPointed: origPubId,
        referenceModule: address(0),
        referenceModuleInitData: "",
        referenceModuleData: ""
      })
    );
  }

  function hubPost() public override returns (uint256) {
    vm.prank(userTwo);
    origPubId = hub.post(
      LensDataTypes.PostData({
        profileId: userTwoProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    vm.prank(publisher);
    uint256 mirrorId = hub.mirror(
      LensDataTypes.MirrorData({
        profileId: publisherProfileId,
        profileIdPointed: userTwoProfileId,
        pubIdPointed: origPubId,
        referenceModule: address(0),
        referenceModuleInitData: "",
        referenceModuleData: ""
      })
    );
    return mirrorId;
  }

  function testCurrentCollectsIncreaseProperlyWhenCollecting() public override {
    uint256 secondPubId = hubPost();
    vm.startPrank(user);

    DataTypes.ProfilePublicationData memory fetchedData = gitcoinCollectModule.getPublicationData(
      userTwoProfileId,
      origPubId
    );
    assertEq(fetchedData.currentCollects, 0);

    for (uint256 collects = 1; collects < 5; collects++) {
      currency.mint(user, 1 ether);
      hub.collect(publisherProfileId, secondPubId, abi.encode(address(currency), 1 ether));
      fetchedData = gitcoinCollectModule.getPublicationData(userTwoProfileId, origPubId);
      assertEq(fetchedData.currentCollects, collects);
    }
    vm.stopPrank();
  }
}

contract GitcoinCollectModule_FeeDistribution is GitcoinCollectModuleBase {
  struct Balances {
    uint256 treasury;
    uint256 referral;
    uint256 publisher;
    uint256 user;
    uint256 userTwo;
  }

  uint256 immutable publisherProfileId;
  uint256 immutable userProfileId;
  uint256 immutable mirrorerProfileId;

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

    mirrorerProfileId = hub.createProfile(
      LensDataTypes.CreateProfileData({
        to: userTwo,
        handle: "usertwo.lens",
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
    exampleInitData.recipient = publisher;

    currency.mint(user, type(uint256).max);
    vm.prank(user);
    currency.approve(collectModuleAddr, type(uint256).max);
  }

  function hubPostAndMirror(uint16 referralFee) public returns (uint256, uint256) {
    exampleInitData.referralFee = referralFee;
    vm.prank(publisher);
    uint256 pubId = hub.post(
      LensDataTypes.PostData({
        profileId: publisherProfileId,
        contentURI: MOCK_URI,
        collectModule: collectModuleAddr,
        collectModuleInitData: getEncodedInitData(),
        referenceModule: address(0),
        referenceModuleInitData: ""
      })
    );

    vm.prank(userTwo);
    uint256 mirrorId = hub.mirror(
      LensDataTypes.MirrorData({
        profileId: mirrorerProfileId,
        profileIdPointed: publisherProfileId,
        pubIdPointed: pubId,
        referenceModule: address(0),
        referenceModuleInitData: "",
        referenceModuleData: ""
      })
    );
    return (pubId, mirrorId);
  }

  function verifyFeesWithoutMirror(uint128 amount) public {
    (uint256 pubId, ) = hubPostAndMirror(0);

    Balances memory balancesBefore;
    Balances memory balancesAfter;
    Balances memory balancesChange;

    balancesBefore.publisher = currency.balanceOf(publisher);
    balancesBefore.user = currency.balanceOf(user);

    vm.prank(user);
    vm.recordLogs();
    hub.collect(publisherProfileId, pubId, abi.encode(address(currency), amount));
    Vm.Log[] memory entries = vm.getRecordedLogs();

    balancesAfter.publisher = currency.balanceOf(publisher);
    balancesAfter.user = currency.balanceOf(user);

    balancesChange.publisher = balancesAfter.publisher - balancesBefore.publisher;
    balancesChange.user = balancesBefore.user - balancesAfter.user;

    assertEq(balancesChange.publisher, amount);
    assertEq(balancesChange.user, amount);

    if (amount == 0) {
      vm.expectRevert("No Transfer event found");
      TestHelpers.getTransferFromEvents(entries, user, publisher);
      assertEq(balancesChange.publisher, 0);
      assertEq(balancesChange.user, 0);
    } else {
      uint256 ownerFeeTransferEventAmount = TestHelpers.getTransferFromEvents(entries, user, publisher);
      assertEq(ownerFeeTransferEventAmount, amount);
    }
  }

  function verifyFeesWithMirror(uint16 referralFee, uint128 amount) public {
    (, uint256 mirrorId) = hubPostAndMirror(referralFee);

    Vm.Log[] memory entries;

    Balances memory balancesBefore;
    Balances memory balancesAfter;
    Balances memory balancesChange;

    balancesBefore.referral = currency.balanceOf(userTwo);
    balancesBefore.publisher = currency.balanceOf(publisher);
    balancesBefore.user = currency.balanceOf(user);

    vm.recordLogs();
    vm.prank(user);
    hub.collect(mirrorerProfileId, mirrorId, abi.encode(address(currency), amount));
    entries = vm.getRecordedLogs();

    balancesAfter.referral = currency.balanceOf(userTwo);
    balancesAfter.publisher = currency.balanceOf(publisher);
    balancesAfter.user = currency.balanceOf(user);

    balancesChange.referral = balancesAfter.referral - balancesBefore.referral;
    balancesChange.publisher = balancesAfter.publisher - balancesBefore.publisher;
    balancesChange.user = balancesBefore.user - balancesAfter.user;

    assertEq(balancesChange.referral + balancesChange.publisher, balancesChange.user);

    uint256 adjustedAmount = amount;
    uint256 referralAmount = (adjustedAmount * referralFee) / BPS_MAX;

    if (referralFee != 0) adjustedAmount = adjustedAmount - referralAmount;

    assertEq(balancesChange.referral, referralAmount);
    assertEq(balancesChange.publisher, adjustedAmount);
    assertEq(balancesChange.user, amount);

    if (amount == 0 || adjustedAmount == 0) {
      vm.expectRevert("No Transfer event found");
      TestHelpers.getTransferFromEvents(entries, user, publisher);
      assertEq(balancesChange.referral, 0);
      assertEq(balancesChange.publisher, 0);
      assertEq(balancesChange.user, 0);
    } else {
      uint256 ownerFeeTransferEventAmount = TestHelpers.getTransferFromEvents(entries, user, publisher);
      assertEq(ownerFeeTransferEventAmount, adjustedAmount);
    }

    if (referralFee == 0 || referralAmount == 0) {
      vm.expectRevert("No Transfer event found");
      TestHelpers.getTransferFromEvents(entries, user, userTwo);
      assertEq(balancesChange.referral, referralAmount);
    } else {
      uint256 referralTransferEventAmount = TestHelpers.getTransferFromEvents(entries, user, userTwo);
      assertEq(referralTransferEventAmount, referralAmount);
    }
  }

  function testFeesDistributionEdgeCasesWithoutMirror() public virtual {
    verifyFeesWithoutMirror(1 ether);
    verifyFeesWithoutMirror(type(uint128).max);
  }

  function testFeesDistributionWithoutMirrorFuzzing(uint128 amount) public virtual {
    vm.assume(amount > 0);
    verifyFeesWithoutMirror(amount);
  }

  function testFeesDistributionEdgeCasesWithMirror() public virtual {
    verifyFeesWithMirror(0, type(uint128).max);
    verifyFeesWithMirror(BPS_MAX / 2 - 1, type(uint128).max);
    verifyFeesWithMirror(0, 1);
    verifyFeesWithMirror(1, 1);
  }

  function testFeesDistributionWithMirrorFuzzing(uint16 referralFee, uint128 amount) public virtual {
    vm.assume(amount > 0);
    referralFee = uint16(bound(referralFee, 0, BPS_MAX / 2 - 2));
    verifyFeesWithMirror(referralFee, amount);
  }
}

/////////
// Publication Creation with BaseFeeCollectModule
//
contract GitcoinCollectModule_GasReport is GitcoinCollectModuleBase {
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

  function testCreatePublicationWithDifferentInitData() public {
    bool followerOnly = false;

    for (uint16 referralFee = 0; referralFee <= BPS_MAX; referralFee++) {
      if (referralFee >= 2) referralFee += BPS_MAX / 4;
      if (referralFee > 9000) referralFee = BPS_MAX;

      exampleInitData.roundAddress = address(round);
      exampleInitData.projectId = MOCK_PROJECT_ID;
      exampleInitData.applicationIndex = 1;
      exampleInitData.currency = address(currency);
      exampleInitData.referralFee = referralFee;
      exampleInitData.followerOnly = followerOnly;
      exampleInitData.recipient = me;

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
  }
}
