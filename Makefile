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
deploy-anvil :; ./script/deploy.sh anvil ${contract}
deploy-sandbox :; ./script/deploy.sh sandbox ${contract}
deploy-testnet :; ./script/deploy.sh testnet ${contract} --verify
deploy-mainnet :; ./script/deploy.sh mainnet ${contract} --verify

deploy-contracts :; make deploy-${network} contract=GitcoinCollectModule && \
	make deploy-${network} contract=LensCollectVotingStrategyFactory && \
	make deploy-${network} contract=LensCollectVotingStrategyImplementation;

deploy-all :; make deploy-contracts network=${network} && \
	make deploy-${network} contract=MerklePayoutStrategyFactory && \
	make deploy-${network} contract=ProgramFactory && \
	make deploy-${network} contract=RoundFactory;

# execute commands
create-round :; script/execute.sh ${network} RoundFactory RoundCreate
