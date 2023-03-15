// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {LensHub} from "@aave/lens-protocol/contracts/core/LensHub.sol";
import {FollowNFT} from "@aave/lens-protocol/contracts/core/FollowNFT.sol";
import {CollectNFT} from "@aave/lens-protocol/contracts/core/CollectNFT.sol";
import {TransparentUpgradeableProxy} from "@aave/lens-protocol/contracts/upgradeability/TransparentUpgradeableProxy.sol";

import {LensPeriphery} from "@aave/lens-protocol/contracts/misc/LensPeriphery.sol";
import {UIDataProvider} from "@aave/lens-protocol/contracts/misc/UIDataProvider.sol";
import {ProfileCreationProxy} from "@aave/lens-protocol/contracts/misc/ProfileCreationProxy.sol";

import {Currency} from "@aave/lens-protocol/contracts/mocks/Currency.sol";

import {GitcoinCollectModule} from "../src/GitcoinCollectModule.sol";

import {BaseDeployScript} from "./BaseDeployScript.sol";
import "forge-std/Script.sol";

contract DeployGitcoinCollectModule is BaseDeployScript {
  string constant LENS_HUB_NFT_NAME = "Lens Protocol Profiles";
  string constant LENS_HUB_NFT_SYMBOL = "LPP";

  constructor() BaseDeployScript() {
    // empty
  }

  function deploy() internal override returns (DeployResult memory) {
    address hubProxyAddress = activeNetworkConfig.lensHub;

    vm.startBroadcast();

    if (hubProxyAddress == address(0)) {
      hubProxyAddress = _deployLensHub(); // this deploys a mock
    }

    address gitcoinCollectModuleAddr = address(new GitcoinCollectModule(hubProxyAddress));

    vm.stopBroadcast();

    return DeployResult({gitcoinCollectModule: gitcoinCollectModuleAddr, votingStrategyFactory: address(0)});
  }

  function _deployLensHub() internal returns (address) {
    address governance = deployer;
    uint256 deployerNonce = vm.getNonce(deployer);

    address followNFTImplAddress = computeCreateAddress(deployer, ++deployerNonce);
    address collectNFTImplAddress = computeCreateAddress(deployer, ++deployerNonce);
    address hubProxyAddress = computeCreateAddress(deployer, ++deployerNonce);

    LensHub lensHubImpl = new LensHub(followNFTImplAddress, collectNFTImplAddress);

    new FollowNFT(hubProxyAddress);
    new CollectNFT(hubProxyAddress);

    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
      address(lensHubImpl),
      msg.sender,
      abi.encodeWithSelector(LensHub.initialize.selector, LENS_HUB_NFT_NAME, LENS_HUB_NFT_SYMBOL, governance)
    );

    return address(proxy);
  }
}
