// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import {LensHub} from "@aave/lens-protocol/contracts/core/LensHub.sol";
import {FollowNFT} from "@aave/lens-protocol/contracts/core/FollowNFT.sol";
import {CollectNFT} from "@aave/lens-protocol/contracts/core/CollectNFT.sol";
import {TransparentUpgradeableProxy} from "@aave/lens-protocol/contracts/upgradeability/TransparentUpgradeableProxy.sol";

import {MockRoundImplementation} from "../test/mocks/MockRoundImplementation.sol";

struct NetworkConfig {
  address lensHub;
  address roundFactory;
}

contract HelperConfig is StdUtils {
  uint16 TREASURY_FEE_BPS;
  address deployer = address(this);

  NetworkConfig public activeNetworkConfig;

  mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

  constructor() {
    chainIdToNetworkConfig[137] = getPolygonConfig();
    chainIdToNetworkConfig[80001] = getMumbaiConfig();
    chainIdToNetworkConfig[31337] = getAnvilEthConfig();

    activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
  }

  function getPolygonConfig() internal pure returns (NetworkConfig memory polygonNetworkConfig) {
    polygonNetworkConfig = NetworkConfig({
      lensHub: 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d, // This is a mock
      roundFactory: address(0) // This is a mock
    });
  }

  function getMumbaiConfig() internal pure returns (NetworkConfig memory mumbaiNetworkConfig) {
    mumbaiNetworkConfig = NetworkConfig({
      lensHub: 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82, // This is a mock
      roundFactory: address(0) // This is a mock
    });
  }

  function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
    anvilNetworkConfig = NetworkConfig({
      lensHub: address(0), // This is a mock
      roundFactory: address(0) // This is a mock
    });
  }

  function deployLensHub() public returns (LensHub) {
    TREASURY_FEE_BPS = 50;

    // Precompute needed addresss.
    address followNFTAddr = computeCreateAddress(deployer, 1);
    address collectNFTAddr = computeCreateAddress(deployer, 2);
    address hubProxyAddr = computeCreateAddress(deployer, 3);

    // Deploy implementation contracts.
    LensHub hubImpl = new LensHub(followNFTAddr, collectNFTAddr);
    new FollowNFT(hubProxyAddr);
    new CollectNFT(hubProxyAddr);

    // Deploy and initialize proxy.
    bytes memory initData = abi.encodeWithSelector(
      hubImpl.initialize.selector,
      "Lens Protocol Profiles",
      "LPP",
      0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    );

    new TransparentUpgradeableProxy(address(hubImpl), deployer, initData);

    return LensHub(hubProxyAddr);
  }

  function deployRoundImplementation() public returns (MockRoundImplementation) {
    MockRoundImplementation roundImpl = new MockRoundImplementation();
    return roundImpl;
  }
}
