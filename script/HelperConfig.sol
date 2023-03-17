// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

struct NetworkConfig {
  address currency;
  address lensHub;
  address gitcoinCollectModule;
  address votingStrategyFactoryContract;
  address votingStrategyImplementationContract;
  address payoutStrategyFactoryContract;
  address payoutStrategyImplementationContract;
  address roundFactoryContract;
  address roundImplementationContract;
  address roundContract;
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
      currency: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
      lensHub: 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d,
      gitcoinCollectModule: address(0), // This is a mock
      votingStrategyFactoryContract: address(0), // This is a mock
      votingStrategyImplementationContract: address(0), // This is a mock
      payoutStrategyFactoryContract: address(0), // This is a mock
      payoutStrategyImplementationContract: address(0), // This is a mock
      roundFactoryContract: address(0), // This is a mock
      roundImplementationContract: address(0), // This is a mock
      roundContract: address(0) // This is a mock
    });
  }

  function getMumbaiConfig() internal pure returns (NetworkConfig memory mumbaiNetworkConfig) {
    mumbaiNetworkConfig = NetworkConfig({
      currency: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
      lensHub: 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82,
      gitcoinCollectModule: address(0), // This is a mock
      votingStrategyFactoryContract: address(0), // This is a mock
      votingStrategyImplementationContract: address(0), // This is a mock
      payoutStrategyFactoryContract: address(0), // This is a mock
      payoutStrategyImplementationContract: address(0), // This is a mock
      roundFactoryContract: address(0), // This is a mock
      roundImplementationContract: address(0), // This is a mock
      roundContract: address(0) // This is a mock
    });
  }

  function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
    anvilNetworkConfig = NetworkConfig({
      currency: address(0),
      lensHub: address(0), // This is a mock
      gitcoinCollectModule: 0x0165878A594ca255338adfa4d48449f69242Eb8F,
      votingStrategyFactoryContract: address(0), // This is a mock
      votingStrategyImplementationContract: address(0), // This is a mock
      payoutStrategyFactoryContract: address(0), // This is a mock
      payoutStrategyImplementationContract: address(0), // This is a mock
      roundFactoryContract: address(0), // This is a mock
      roundImplementationContract: address(0), // This is a mock
      roundContract: address(0) // This is a mock
    });
  }
}
