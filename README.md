# Grants Collect Module

This repository contains contracts to run a Gitcoin grants round on Lens protocol. This module allows Lens users to apply to a Gitcoin grants round with their publication and receive contributions from any dapp that supports Lens protocol.

This module is an experiment while playing with Kevin Owocki's idea of a quadratic funding social network posted [here](https://community.supermodular.xyz/t/sip-cohort-2-opportunity-2-quadratic-funding-social-network/94). Be sure to check out the discussion as it contains useful information on how this package works.

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/izziaraffaele/grants-collect-module)

# Getting Started

## Requirements

Please install [Foundry / Foundryup](https://github.com/gakonst/foundry):

- This will install `forge`, `cast`, and `anvil`
- You can test you've installed them right by running `forge --version` and get an output like: `forge 0.2.0 (f016135 2022-07-04T00:15:02.930499Z)`
- To get the latest of each, just run `foundryup`

And you probably already have `make` installed... but if not [try looking here.](https://askubuntu.com/questions/161104/how-do-i-install-make)

## Quickstart

```sh
git clone https://github.com/izziaraffaele/grants-collect-module
cd grants-collect-module
yarn install # This install some of the project's dependencies managed with yarn
make # This installs the project's dependencies managed with Foundry.
make test
```

## Testing

```
make test
```

or

```
forge test
```

# Deploying to a network

Deploying to a network uses the [foundry scripting system](https://book.getfoundry.sh/tutorials/solidity-scripting.html), where you write your deploy scripts in solidity!

## Setup

We'll demo using the Mumai testnet. (Go here for [testnet mumbai MATIC](https://faucet.polygon.technology/).)

You'll need to add the following variables to a `.env` file:

- `MUMBAI_RPC_URL`: A URL to connect to the blockchain. You can get one for free from [Infura](https://www.infura.io/) account
- `PRIVATE_KEY`: A private key from your wallet. You can get a private key from a new [Metamask](https://metamask.io/) account
- Optional `ETHERSCAN_API_KEY`: If you want to verify on etherscan

## Deploying

```
make deploy-all network=<sandbox|testnet|mainnet>
```

This will deploy all the contracts in this repository on a specific network. It will also deploy and configure a Gitcoin Round. You'll find deployed contract addresses in `addresses.json`.

Alternatively you can use the following commands to deploy only the contracts in this repo.

```
make deploy-contracts network=<sandbox|testnet|mainnet>
```

To deploy only a specific contract use the following command

```
make deploy-testnet contract=<CONTRACT_NAME>
```

For example:

```
make deploy-testnet contract=GitcoinCollectModule
```

These commands pull from the files in the `script` folder.

### Working with a local network

Foundry comes with local network [anvil](https://book.getfoundry.sh/anvil/index.html) baked in, and allows us to deploy to our local network for quick testing locally.

To start a local network run:

```
make anvil
```

This will spin up a local blockchain with a determined private key, so you can use the same private key each time. It creates a fork of the mumbai testnet so the `MUMBAI_RPC_URL` env variable is required to run this command.

Then, you can deploy to it with:

```
make deploy-anvil contract=<CONTRACT_NAME>
```

Similar to `deploy-testnet`

### Working with other chains

To deploy on Polygon mainnet, you can just use `deploy-mainnet` similar to `deploy-testnet`;

# Usage

If all the contracts are deployed correctly you can simply run the following command to create a quadratic funding lens round

```
make create-round network=<sandbox|testnet|mainnet>
```

You are ready to post your publication on Lens!

# Contributing

Contributions are always welcome! Open a PR or an issue!

# Thank You!

## Resources

- [Lens protocol Documentation](https://docs.lens.xyz/)
- [Foundry Documentation](https://book.getfoundry.sh/)
