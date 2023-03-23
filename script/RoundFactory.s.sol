// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AlloSettings} from "allo/settings/AlloSettings.sol";
import {RoundFactory} from "allo/round/RoundFactory.sol";
import {RoundImplementation} from "allo/round/RoundImplementation.sol";
import {ProgramFactory} from "allo/program/ProgramFactory.sol";
import {MerklePayoutStrategyFactory} from "allo/payoutStrategy/MerklePayoutStrategy/MerklePayoutStrategyFactory.sol";
import {IPayoutStrategy} from "allo/payoutStrategy/IPayoutStrategy.sol";
import {IVotingStrategy} from "allo/votingStrategy/IVotingStrategy.sol";
import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployRoundFactory is BaseDeployer {
  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address roundFactory = address(new RoundFactory());
    RoundFactory(roundFactory).initialize();

    address roundImpl = address(new RoundImplementation());
    RoundFactory(roundFactory).updateRoundImplementation(payable(roundImpl));

    address alloSettings = address(new AlloSettings());
    AlloSettings(alloSettings).initialize();
    AlloSettings(alloSettings).updateProtocolTreasury(payable(deployer));

    RoundFactory(roundFactory).updateAlloSettings(alloSettings);

    vm.stopBroadcast();

    return roundFactory;
  }
}

contract ExecuteRoundCreate is BaseDeployer {
  using stdJson for string;

  address payoutStrategyFactory;
  address programFactory;
  address roundFactory;
  address votingStrategyFactory;

  address collectModule;
  address payoutStrategy;
  address votingStrategy;

  function loadBaseAddresses(string memory json, string memory targetEnv) internal override {
    programFactory = json.readAddress(string(abi.encodePacked(".", targetEnv, ".ProgramFactory")));
    payoutStrategyFactory = json.readAddress(string(abi.encodePacked(".", targetEnv, ".MerklePayoutStrategyFactory")));
    roundFactory = json.readAddress(string(abi.encodePacked(".", targetEnv, ".RoundFactory")));
    votingStrategyFactory = json.readAddress(
      string(abi.encodePacked(".", targetEnv, ".LensCollectVotingStrategyFactory"))
    );

    collectModule = json.readAddress(string(abi.encodePacked(".", targetEnv, ".GitcoinCollectModule")));
  }

  function deploy() internal override returns (address) {
    require(programFactory != address(0), "Unknown round factory");
    require(roundFactory != address(0), "Unknown round factory");
    require(payoutStrategyFactory != address(0), "Unknown payout strategy factory");
    require(votingStrategyFactory != address(0), "Unknown voting strategy factory");

    require(collectModule != address(0), "Unknown collect module");

    vm.startBroadcast(deployerPrivateKey);
    address program = ProgramFactory(programFactory).create(getEncodedProgramParams());

    payoutStrategy = MerklePayoutStrategyFactory(payoutStrategyFactory).create();
    votingStrategy = LensCollectVotingStrategyFactory(votingStrategyFactory).create();

    address round = RoundFactory(roundFactory).create(getEncodedRoundParams(), program);

    vm.stopBroadcast();

    return round;
  }

  function getEncodedProgramParams() internal view returns (bytes memory) {
    address[] memory adminRoles = new address[](1);
    adminRoles[0] = deployer;
    address[] memory programOperators = new address[](1);
    programOperators[0] = deployer;

    return abi.encode(getInitMetaPtr(), adminRoles, programOperators);
  }

  function getEncodedRoundParams() internal view returns (bytes memory) {
    return
      abi.encode(
        getInitAddress(),
        getInitRoundTime(),
        0,
        address(0), // token
        0,
        deployer,
        getInitMetaPtr(),
        getInitRoles()
      );
  }

  function getInitAddress() internal view returns (RoundImplementation.InitAddress memory) {
    return
      RoundImplementation.InitAddress({
        votingStrategy: IVotingStrategy(votingStrategy),
        payoutStrategy: IPayoutStrategy(payable(payoutStrategy))
      });
  }

  function getInitRoundTime() internal view returns (RoundImplementation.InitRoundTime memory) {
    uint256 start = block.timestamp + 2 weeks;
    uint256 interval = 24 hours;

    return
      RoundImplementation.InitRoundTime({
        applicationsStartTime: start,
        applicationsEndTime: start + interval,
        roundStartTime: start + (interval * 2),
        roundEndTime: start + (interval * 3)
      });
  }

  function getInitMetaPtr() internal pure returns (RoundImplementation.InitMetaPtr memory) {
    RoundImplementation.InitMetaPtr memory initMetaPtr;
    return initMetaPtr;
  }

  function getInitRoles() internal view returns (RoundImplementation.InitRoles memory) {
    address[] memory adminRoles = new address[](1);
    adminRoles[0] = deployer;

    address[] memory roundOperators = new address[](1);
    roundOperators[0] = deployer;

    return RoundImplementation.InitRoles({adminRoles: adminRoles, roundOperators: roundOperators});
  }
}
