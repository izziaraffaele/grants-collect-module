// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

// Deployments
import {LensHub} from "@aave/lens-protocol/contracts/core/LensHub.sol";
import {FollowNFT} from "@aave/lens-protocol/contracts/core/FollowNFT.sol";
import {CollectNFT} from "@aave/lens-protocol/contracts/core/CollectNFT.sol";
import {TransparentUpgradeableProxy} from "@aave/lens-protocol/contracts/upgradeability/TransparentUpgradeableProxy.sol";
import {DataTypes as LensDataTypes} from "@aave/lens-protocol/contracts/libraries/DataTypes.sol";
import {Errors as LensErrors} from "@aave/lens-protocol/contracts/libraries/Errors.sol";
import {Events as LensEvents} from "@aave/lens-protocol/contracts/libraries/Events.sol";
import {Currency} from "@aave/lens-protocol/contracts/mocks/Currency.sol";

import {Errors} from "../src/libraries/Errors.sol";
import {Events} from "../src/libraries/Events.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {IRoundImplementation} from "../src/interfaces/IRoundImplementation.sol";
import {LensCollectVotingStrategyImplementation} from "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {GitcoinCollectModule} from "../src/GitcoinCollectModule.sol";

import {NFT} from "./mocks/NFT.sol";
import {MockRoundImplementation} from "./mocks/MockRoundImplementation.sol";
import {ForkManagement} from "../script/helpers/ForkManagement.sol";

contract BaseSetup is Test, ForkManagement {
  using stdJson for string;

  string forkEnv;
  bool fork;
  string network;
  string json;
  uint256 forkBlockNumber;

  uint256 firstProfileId;
  address deployer;
  address governance;

  address constant publisher = address(4);
  address constant user = address(5);
  address constant userTwo = address(6);
  address constant userThree = address(7);
  address constant userFour = address(8);
  address constant userFive = address(9);
  address immutable me = address(this);

  string constant MOCK_HANDLE = "mock";
  bytes32 constant MOCK_PROJECT_ID = bytes32("mock-project-id");
  string constant MOCK_URI = "ipfs://QmUXfQWe43RKx31VzA2BnbwhSMW8WuaJvszFWChD59m76U";
  string constant OTHER_MOCK_URI = "https://ipfs.io/ipfs/QmTFLSXdEQ6qsSzaXaCSNtiv6wA56qq87ytXJ182dXDQJS";
  string constant MOCK_FOLLOW_NFT_URI = "https://ipfs.io/ipfs/QmU8Lv1fk31xYdghzFrLm6CiFcwVg7hdgV6BBWesu6EqLj";
  uint16 constant TREASURY_FEE_MAX_BPS = 10000;

  address hubProxyAddr;
  address collectModuleAddr;

  CollectNFT collectNFT;
  FollowNFT followNFT;
  LensHub hubImpl;
  TransparentUpgradeableProxy hubAsProxy;
  GitcoinCollectModule public gitcoinCollectModule;
  LensHub hub;
  Currency currency;
  MockRoundImplementation round;
  LensCollectVotingStrategyImplementation public votingStrategy;

  NFT nft;

  // TODO: Replace with forge-std/StdJson.sol::keyExists(...) when/if this PR is approved:
  //       https://github.com/foundry-rs/forge-std/pull/226
  function keyExists(string memory key) internal view returns (bool) {
    return json.parseRaw(key).length > 0;
  }

  function loadBaseAddresses(string memory _json, string memory _targetEnv) internal virtual {
    bytes32 PROXY_IMPLEMENTATION_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    console.log("targetEnv:", _targetEnv);

    hubProxyAddr = _json.readAddress(string(abi.encodePacked(".", _targetEnv, ".LensHubProxy")));
    console.log("hubProxyAddr:", hubProxyAddr);

    hub = LensHub(hubProxyAddr);

    console.log("Hub:", address(hub));

    address followNFTAddr = hub.getFollowNFTImpl();
    address collectNFTAddr = hub.getCollectNFTImpl();

    address hubImplAddr = address(uint160(uint256(vm.load(hubProxyAddr, PROXY_IMPLEMENTATION_STORAGE_SLOT))));
    console.log("Found hubImplAddr:", hubImplAddr);
    hubImpl = LensHub(hubImplAddr);
    followNFT = FollowNFT(followNFTAddr);
    collectNFT = CollectNFT(collectNFTAddr);
    hubAsProxy = TransparentUpgradeableProxy(payable(address(hub)));

    currency = new Currency();
    nft = new NFT();
    round = new MockRoundImplementation();

    // Deploy ad whitelist the GitcoinCollectModule.
    gitcoinCollectModule = new GitcoinCollectModule(hubProxyAddr);
    collectModuleAddr = address(gitcoinCollectModule);

    // deploy and initialize voting strategy
    votingStrategy = new LensCollectVotingStrategyImplementation();

    firstProfileId = uint256(vm.load(hubProxyAddr, bytes32(uint256(22)))) + 1;
    console.log("firstProfileId:", firstProfileId);

    deployer = address(1);

    governance = hub.getGovernance();
  }

  function deployBaseContracts() internal {
    firstProfileId = 1;
    deployer = address(1);
    governance = address(2);

    ///////////////////////////////////////// Start deployments.
    vm.startPrank(deployer);

    // Precompute needed addresss.
    address followNFTAddr = computeCreateAddress(deployer, 1);
    address collectNFTAddr = computeCreateAddress(deployer, 2);
    hubProxyAddr = computeCreateAddress(deployer, 3);

    // Deploy implementation contracts.
    hubImpl = new LensHub(followNFTAddr, collectNFTAddr);
    followNFT = new FollowNFT(hubProxyAddr);
    collectNFT = new CollectNFT(hubProxyAddr);

    // Deploy and initialize proxy.
    bytes memory initData = abi.encodeWithSelector(
      hubImpl.initialize.selector,
      "Lens Protocol Profiles",
      "LPP",
      governance
    );
    hubAsProxy = new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);

    // Cast proxy to LensHub interface.
    hub = LensHub(address(hubAsProxy));

    currency = new Currency();
    nft = new NFT();
    round = new MockRoundImplementation();

    // Deploy ad whitelist the GitcoinCollectModule.
    gitcoinCollectModule = new GitcoinCollectModule(hubProxyAddr);
    collectModuleAddr = address(gitcoinCollectModule);

    // deploy and initialize voting strategy
    votingStrategy = new LensCollectVotingStrategyImplementation();

    vm.stopPrank();
    ///////////////////////////////////////// End deployments.
  }

  constructor() {
    forkEnv = vm.envString("TESTING_FORK");

    if (bytes(forkEnv).length > 0) {
      fork = true;
      console.log("\n\n Testing using %s fork", forkEnv);
      json = loadJson();

      network = getNetwork(json, forkEnv);
      vm.createSelectFork(network);

      forkBlockNumber = block.number;
      console.log("Fork Block number:", forkBlockNumber);

      checkNetworkParams(json, forkEnv);

      loadBaseAddresses(json, forkEnv);
    } else {
      deployBaseContracts();
    }
    ///////////////////////////////////////// Start governance actions.
    vm.startPrank(governance);

    if (hub.getState() != LensDataTypes.ProtocolState.Unpaused) hub.setState(LensDataTypes.ProtocolState.Unpaused);

    // Whitelist the test contract as a profile creator
    hub.whitelistProfileCreator(me, true);

    hub.whitelistCollectModule(collectModuleAddr, true);

    // assign the voting strategy to the round
    round.setVotingStrategy(address(votingStrategy));
    round.setApplicationStatus(1, 1);

    vm.stopPrank();
    ///////////////////////////////////////// End governance actions.
  }

  function _toUint256Array(uint256 n) internal pure returns (uint256[] memory) {
    uint256[] memory ret = new uint256[](1);
    ret[0] = n;
    return ret;
  }

  function _toBytesArray(bytes memory n) internal pure returns (bytes[] memory) {
    bytes[] memory ret = new bytes[](1);
    ret[0] = n;
    return ret;
  }
}
