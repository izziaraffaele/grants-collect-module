// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import "../src/GitcoinCollectModule.sol";
import "./HelperConfig.sol";

contract DeployGitcoinCollectModule is Script, HelperConfig {
  function run() external {
    HelperConfig helper = new HelperConfig();
    (address lensHub, ) = helper.activeNetworkConfig();

    if (lensHub == address(0)) {
      lensHub = address(deployLensHub());
      console.log("Using LensHub mock at ", lensHub);
    }

    vm.startBroadcast();
    new GitcoinCollectModule(lensHub);

    vm.stopBroadcast();
  }
}
