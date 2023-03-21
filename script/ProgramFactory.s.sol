// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ProgramFactory} from "allo/program/ProgramFactory.sol";
import {ProgramImplementation} from "allo/program/ProgramImplementation.sol";

import {BaseDeployer} from "./BaseDeployer.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract DeployProgramFactory is BaseDeployer {
  function deploy() internal override returns (address) {
    vm.startBroadcast(deployerPrivateKey);

    address programFactory = address(new ProgramFactory());
    ProgramFactory(programFactory).initialize();

    address programImpl = address(new ProgramImplementation());
    ProgramFactory(programFactory).updateProgramContract(programImpl);

    vm.stopBroadcast();

    return programFactory;
  }
}
