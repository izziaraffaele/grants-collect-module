// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors as LensErrors} from "@aave/lens-protocol/contracts/libraries/Errors.sol";

library Errors {
  error NotRoundContract();

  // Voting strategy errors
  error VoteCasted();
  error VoteInvalid();
}
