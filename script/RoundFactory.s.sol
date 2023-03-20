// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {RoundFactory} from "allo/round/RoundFactory.sol";
import {RoundImplementation} from "allo/round/RoundImplementation.sol";
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
    RoundFactory(roundFactory).updateProtocolTreasury(payable(deployer));

    address roundImpl = address(new RoundImplementation());
    RoundFactory(roundFactory).updateRoundContract(payable(roundImpl));

    vm.stopBroadcast();

    return roundFactory;
  }
}

contract ExecuteRoundCreate is BaseDeployer {
  using stdJson for string;

  address roundFactory;
  address payoutStrategyFactory;
  address votingStrategyFactory;

  address collectModule;
  address payoutStrategy;
  address votingStrategy;

  function loadBaseAddresses(string memory json, string memory targetEnv) internal override {
    collectModule = json.readAddress(string(abi.encodePacked(".", targetEnv, ".GitcoinCollectModule")));
    roundFactory = json.readAddress(string(abi.encodePacked(".", targetEnv, ".RoundFactory")));
    payoutStrategyFactory = json.readAddress(string(abi.encodePacked(".", targetEnv, ".MerklePayoutStrategyFactory")));
    votingStrategyFactory = json.readAddress(
      string(abi.encodePacked(".", targetEnv, ".LensCollectVotingStrategyFactory"))
    );

    vm.label(collectModule, "GitcoinCollectModule");
    vm.label(roundFactory, "RoundFactory");
    vm.label(payoutStrategyFactory, "MerklePayoutStrategyFactory");
    vm.label(votingStrategyFactory, "LensCollectVotingStrategyFactory");
  }

  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    payoutStrategy = MerklePayoutStrategyFactory(payoutStrategyFactory).create();
    votingStrategy = LensCollectVotingStrategyFactory(votingStrategyFactory).create(collectModule);

    vm.label(payoutStrategyFactory, "MerklePayoutStrategyInstance");
    vm.label(votingStrategyFactory, "LensCollectVotingStrategyInstance");

    address round = RoundFactory(roundFactory).create(getEncodedRoundParams(), deployer);

    vm.stopBroadcast();

    return round;
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
