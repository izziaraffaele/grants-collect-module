// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
  error Initialized();
  error InitParamsInvalid();
  error NotRoundContract();

  // Collect module errors
  error ModuleDataMismatch();

  // Voting strategy errors
  error VoteCasted();
  error VoteInvalid();
}
