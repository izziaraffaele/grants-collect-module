// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {RoundFactory} from "allo/round/RoundFactory.sol";
import {RoundImplementation} from "allo/round/RoundImplementation.sol";
import {MetaPtr} from "allo/utils/MetaPtr.sol";
import {IVotingStrategy} from "allo/votingStrategy/IVotingStrategy.sol";
import {MerklePayoutStrategyFactory} from "allo/payoutStrategy/MerklePayoutStrategy/MerklePayoutStrategyFactory.sol";
import {MerklePayoutStrategyImplementation} from "allo/payoutStrategy/MerklePayoutStrategy/MerklePayoutStrategyImplementation.sol";
import {IPayoutStrategy} from "allo/payoutStrategy/IPayoutStrategy.sol";

import {ILensCollectVotingStrategy} from "../src/interfaces/ILensCollectVotingStrategy.sol";
import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

import {BaseDeployScript} from "./BaseDeployScript.sol";
import {HelperConfig} from "./HelperConfig.sol";
import "forge-std/Script.sol";

contract DeployRoundImplementation is BaseDeployScript {
  constructor() BaseDeployScript() {
    // empty
  }

  function deploy() internal override {
    vm.startBroadcast();

    _deployRoundFactory();

    if (activeNetworkConfig.payoutStrategyFactoryContract == address(0)) {
      _deployPayoutStrategy();
    }

    vm.stopBroadcast();
  }

  function _deployRoundFactory() internal returns (address) {
    // deploy round implementation contract
    address roundImplementationContract = address(new RoundImplementation());

    // deploy round factory contract
    RoundFactory roundFactory = new RoundFactory();

    // configure round factory
    roundFactory.initialize();
    roundFactory.updateRoundContract(payable(roundImplementationContract));
    roundFactory.updateProtocolTreasury(payable(deployer));

    return address(roundFactory);
  }

  function _deployPayoutStrategy() internal returns (address) {
    MerklePayoutStrategyFactory factory = new MerklePayoutStrategyFactory();
    factory.initialize();

    address payoutStrategyImpl = address(new MerklePayoutStrategyImplementation());

    factory.updatePayoutImplementation(payable(payoutStrategyImpl));
    return address(factory);
  }
}

contract CreateRoundImplementation is Script, HelperConfig {
  using stdJson for string;

  struct RoundFactoryAddr {
    address payoutStrategyFactoryContract;
    address roundFactoryContract;
    address votingStrategyFactoryContract;
  }

  struct RoundConfig {
    RoundFactoryAddr factoryAddr;
    uint256 matchAmount;
    RoundImplementation.InitRoles roles;
    address payable roundFeeAddress;
    uint8 roundFeePercentage;
    InitRoundTime roundTime;
    address token;
  }

  struct InitRoundTime {
    uint256 applicationsEndTime; // Unix timestamp from when round stops accepting applications
    uint256 applicationsStartTime; // Unix timestamp from when round can accept applications
    uint256 roundEndTime; // Unix timestamp of the end of the round
    uint256 roundStartTime; // Unix timestamp of the start of the round
  }

  constructor() HelperConfig() {
    //empty
  }

  function run() external {
    RoundConfig memory roundConfig = parseInput("round-data");

    require(roundConfig.factoryAddr.roundFactoryContract != address(0), "Unknown round factory");
    require(roundConfig.factoryAddr.votingStrategyFactoryContract != address(0), "Unknown voting strategy");
    require(roundConfig.factoryAddr.payoutStrategyFactoryContract != address(0), "Unknown payout strategy");

    vm.label(roundConfig.factoryAddr.roundFactoryContract, "RoundFactory");
    vm.label(roundConfig.factoryAddr.votingStrategyFactoryContract, "VotingStrategyFactory");
    vm.label(roundConfig.factoryAddr.payoutStrategyFactoryContract, "PayoutStrategyFactory");

    vm.startBroadcast();

    address votingStrategyContract = LensCollectVotingStrategyFactory(
      roundConfig.factoryAddr.votingStrategyFactoryContract
    ).create(activeNetworkConfig.gitcoinCollectModule);

    vm.label(votingStrategyContract, "VotingStrategy");

    address payoutStrategyContract = MerklePayoutStrategyFactory(roundConfig.factoryAddr.payoutStrategyFactoryContract)
      .create();
    vm.label(payoutStrategyContract, "PayoutStrategy");

    RoundImplementation.InitMetaPtr memory dummyInitMetaPtr;

    RoundFactory(roundConfig.factoryAddr.roundFactoryContract).create(
      abi.encode(
        RoundImplementation.InitAddress({
          votingStrategy: IVotingStrategy(votingStrategyContract),
          payoutStrategy: IPayoutStrategy(payable(payoutStrategyContract))
        }),
        RoundImplementation.InitRoundTime({
          applicationsStartTime: roundConfig.roundTime.applicationsStartTime,
          applicationsEndTime: roundConfig.roundTime.applicationsEndTime,
          roundStartTime: roundConfig.roundTime.roundStartTime,
          roundEndTime: roundConfig.roundTime.roundEndTime
        }),
        roundConfig.matchAmount,
        roundConfig.token,
        roundConfig.roundFeePercentage,
        roundConfig.roundFeeAddress,
        dummyInitMetaPtr,
        roundConfig.roles
      ),
      msg.sender
    );

    vm.stopBroadcast();
  }

  function parseInput(string memory input) internal returns (RoundConfig memory) {
    string memory json = readInput(input);

    RoundConfig memory parsed;

    parsed.factoryAddr = abi.decode(json.parseRaw(".factoryAddr"), (RoundFactoryAddr));
    parsed.matchAmount = json.readUint(".matchAmount");
    parsed.roles = abi.decode(json.parseRaw(".roles"), (RoundImplementation.InitRoles));
    parsed.roundFeeAddress = payable(parsed.token = abi.decode(json.parseRaw(".roundFeeAddress"), (address)));
    parsed.roundFeePercentage = uint8(json.readUint(".roundFeePercentage"));
    parsed.roundTime = abi.decode(json.parseRaw(".roundTime"), (InitRoundTime));
    parsed.token = abi.decode(json.parseRaw(".token"), (address));

    return parsed;
  }

  function readInput(string memory input) internal returns (string memory) {
    string memory inputDir = string.concat(vm.projectRoot(), "/script/input/");
    string memory chainDir = string.concat(vm.toString(block.chainid), "/");
    string memory file = string.concat(input, ".json");
    return vm.readFile(string.concat(inputDir, chainDir, file));
  }
}
