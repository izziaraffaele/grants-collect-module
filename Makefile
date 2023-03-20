-include .env

.PHONY: all test clean deploy-anvil

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std && forge install allo-protocol/contracts

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test

snapshot :; forge snapshot

slither :; slither ./src

format :; prettier --write src/**/*.sol && prettier --write src/*.sol

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk' --fork-url ${MUMBAI_RPC_URL}

# deploy commands
deploy-sandbox :; ./script/deploy.sh sandbox ${contract}
deploy-mumbai :; ./script/deploy.sh mumbai ${contract}
deploy-mainnet :; ./script/deploy.sh mainnet ${contract}

deploy-contracts :; make deploy-${network} contract=GitcoinCollectModule && \
	make deploy-${network} contract=LensCollectVotingStrategyFactory && \
	make deploy-${network} contract=LensCollectVotingStrategyImplementation;

deploy-all :; make deploy-contracts network=${network} && \
	make deploy-${network} contract=MerklePayoutStrategyFactory && \
	make deploy-${network} contract=RoundFactory;

# use the "@" to hide the command from your shell
# deploy-mumbai :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${MUMBAI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}   -vvvv -g 160 --resume  --slow

# deploy-polygon :; forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${POLIGON_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv -g 160 --resume  --slow

# # This is the private key of account from the mnemonic from the "make anvil" command
# deploy-anvil :; PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 @forge script script/${contract}.s.sol:Deploy${contract} -s $(cast calldata "run(string)" sandbox) --rpc-url http://localhost:8545 --broadcast

# deploy-all :; make deploy-${network} contract=GitcoinCollectModule && make deploy-${network} contract=LensCollectVotingStrategy && make deploy-${network} contract=RoundImplementation

# PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/LensCollectVotingStrategy.s.sol:DeployLensCollectVotingStrategy -s $(cast calldata "run(string)" sandbox) --rpc-url http://localhost:8545
