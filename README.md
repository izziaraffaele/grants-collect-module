# Grants Collect Module

This repository contains contracts to run a Gitcoin grants round on Lens protocol. This module allows Lens users to apply to a Gitcoin grants round with their publication and receive contributions from any dapp that supports Lens protocol.

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
make deploy-mumbai contract=<CONTRACT_NAME>
```

For example:

```
make deploy-mumbai contract=VotingStrategyFactory
```

This will run the forge script, the script it's running is:

```
@forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${SEPOLIA_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv
```

If you don't have an `ETHERSCAN_API_KEY`, you can also just run:

```
@forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${MUMBAI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast
```

These pull from the files in the `script` folder.

### Working with a local network

Foundry comes with local network [anvil](https://book.getfoundry.sh/anvil/index.html) baked in, and allows us to deploy to our local network for quick testing locally.

To start a local network run:

```
make anvil
```

This will spin up a local blockchain with a determined private key, so you can use the same private key each time.

Then, you can deploy to it with:

```
make deploy-anvil contract=<CONTRACT_NAME>
```

Similar to `deploy-mumbai`

### Working with other chains

To deploy on Polygon mainnet, you can just use `deploy-polygon` similar to `deploy-mumbai`;

To add a chain, you'd just need to make a new entry in the `Makefile`, and replace `<YOUR_CHAIN>` with whatever your chain's information is.

```
deploy-<YOUR_CHAIN> :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${<YOUR_CHAIN>_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv
```

# Contributing

Contributions are always welcome! Open a PR or an issue!

# Thank You!

## Resources

- [Lens protocol Documentation](https://docs.lens.xyz/)
- [Foundry Documentation](https://book.getfoundry.sh/)
