// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

struct NetworkConfig {
  address lensHub;
  address roundFactory;
}

contract HelperConfig {
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
}
