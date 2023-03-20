// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {MerklePayoutStrategyFactory} from "allo/payoutStrategy/MerklePayoutStrategy/MerklePayoutStrategyFactory.sol";
import {MerklePayoutStrategyImplementation} from "allo/payoutStrategy/MerklePayoutStrategy/MerklePayoutStrategyImplementation.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployMerklePayoutStrategyFactory is BaseDeployer {
  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address payoutStrategyFactory = address(new MerklePayoutStrategyFactory());
    MerklePayoutStrategyFactory(payoutStrategyFactory).initialize();

    address payoutStrategyImpl = address(new MerklePayoutStrategyImplementation());
    MerklePayoutStrategyFactory(payoutStrategyFactory).updatePayoutImplementation(payable(payoutStrategyImpl));

    vm.stopBroadcast();

    return payoutStrategyFactory;
  }
}
