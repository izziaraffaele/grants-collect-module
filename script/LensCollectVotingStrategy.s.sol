// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {LensCollectVotingStrategyImplementation} from "../src/votingStrategy/LensCollectVotingStrategyImplementation.sol";
import {LensCollectVotingStrategyFactory} from "../src/votingStrategy/LensCollectVotingStrategyFactory.sol";

import {BaseDeployScript} from "./BaseDeployScript.sol";
import "forge-std/Script.sol";

contract DeployLensCollectVotingStrategy is BaseDeployScript {
  string constant LENS_HUB_NFT_NAME = "Lens Protocol Profiles";
  string constant LENS_HUB_NFT_SYMBOL = "LPP";

  constructor() BaseDeployScript() {
    // empty
  }

  function deploy() internal override returns (DeployResult memory) {
    vm.startBroadcast();

    address strategyImpl = address(new LensCollectVotingStrategyImplementation());

    LensCollectVotingStrategyFactory factory = new LensCollectVotingStrategyFactory();

    factory.initialize();
    factory.updateVotingContract(strategyImpl);

    vm.stopBroadcast();

    return DeployResult({gitcoinCollectModule: address(0), votingStrategyFactory: address(factory)});
  }
}
