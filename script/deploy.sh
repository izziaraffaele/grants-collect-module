#!/bin/bash
source .env

set -e

if [[ $1 == "" || $2 == "" || ($3 != "--verify-only" && $3 != "")]]
    then
        echo "Usage:"
        echo "  deploy.sh [target environment] [contractName] --verify-only [constructor-args]"
        echo "    where target environment (required): mainnet / testnet / sandbox"
        echo "    where contractName (required): contract name you want to deploy"
        echo "    --verify-only: if you only want to verify the existing deployment source code"
        echo "                   [constructor-args] are ABI-Encoded for verification (see 'cast abi-encode' docs)"
        echo ""
        echo "Example:"
        echo "  deploy.sh sandbox GitcoinCollectModule"
        exit 1
fi

if [[ $1 == "mainnet" ]]
    then
        VERIFIER_URL=$MAINNET_EXPLORER_API
    else
        if [[ $1 == "testnet" || $1 == "sandbox" ]]
            then
                VERIFIER_URL=$TESTNET_EXPLORER_API
            else
                echo "Unrecognized target environment '$1'. Should be one of mainnet/testnet/sandbox"
                exit 1
        fi
fi

NETWORK=$(node script/helpers/readNetwork.js $1)
if [[ $NETWORK == "" ]]
    then
        echo "No network found for $1 environment target in addresses.json. Terminating"
        exit 1
fi

SAVED_ADDRESS=$(node script/helpers/readAddress.js $1 $2)

echo $SAVED_ADDRESS
if [[ $3 == "--verify-only" ]]
    then
        echo "Running in verify-only mode (will verify the source code of existing deployment)"
        if [[ $SAVED_ADDRESS != "" ]]
            then
                echo "Found $2 on '$1' at: $SAVED_ADDRESS"
                read -p "Should we proceed with verification? (y/n):" CONFIRMATION
                if [[ $CONFIRMATION != "y" && $CONFIRMATION != "Y" ]]
                    then
                    echo "Verification cancelled. Execution terminated."
                    exit 1
                fi
                echo "forge verify-contract $SAVED_ADDRESS $2 $BLOCK_EXPLORER_KEY --verifier-url "$VERIFIER_URL" --constructor-args "$4" --watch"
                forge verify-contract $SAVED_ADDRESS $2 $BLOCK_EXPLORER_KEY --verifier-url "$VERIFIER_URL" --constructor-args "$4" --watch
                exit 0
            else
                echo "Can't find the $2 deployment address on '$1' for verification. Terminating"
                exit 1
        fi
fi

if [[ $SAVED_ADDRESS != "" ]]
    then
        echo "Found $2 already deployed on $1 at: $SAVED_ADDRESS"
        read -p "Should we redeploy it? (y/n):" CONFIRMATION
        if [[ $CONFIRMATION != "y" && $CONFIRMATION != "Y" ]]
            then
            echo "Deployment cancelled. Execution terminated."
            exit 1
        fi
fi

if [[ $PRIVATE_KEY == "" && $1 == "sandbox" ]]
    then
        PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
fi

CALLDATA=$(cast calldata "run(string)" $1)
PRIVATE_KEY=$PRIVATE_KEY forge script script/$2.s.sol:Deploy$2 -s $CALLDATA --rpc-url $NETWORK

read -p "Please verify the data and confirm the deployment (y/n):" CONFIRMATION

if [[ $CONFIRMATION == "y" || $CONFIRMATION == "Y" ]]
    then
        echo "Deploying..."

        FORGE_OUTPUT=$(PRIVATE_KEY=$PRIVATE_KEY forge script script/$2.s.sol:Deploy$2 -s $CALLDATA --rpc-url $NETWORK --broadcast)
        echo "$FORGE_OUTPUT"

        DEPLOYED_ADDRESS=$(echo "$FORGE_OUTPUT" | grep "Contract Address:" | sed -n 's/.*: \(0x[0-9a-hA-H]\{40\}\)/\1/p')

        if [[ $DEPLOYED_ADDRESS == "" ]]
            then
                echo "Cannot find Deployed address of $2 in foundry logs. Terminating"
                exit 1
        fi

        node script/helpers/saveAddress.js $1 $2 $DEPLOYED_ADDRESS

        CONSTRUCTOR_ARGS=$(echo "$FORGE_OUTPUT" | awk '/Constructor arguments:/{getline; gsub(/ /,""); print}')
        echo "($CONSTRUCTOR_ARGS)"

        echo ""
        read -p "Proceed with verification? (y/n):" CONFIRMATION
        if [[ $CONFIRMATION == "y" || $CONFIRMATION == "Y" ]]
            then
                forge verify-contract $DEPLOYED_ADDRESS $2 $BLOCK_EXPLORER_KEY --verifier-url "$VERIFIER_URL" --constructor-args "$CONSTRUCTOR_ARGS" --watch
            else
                echo "Verification cancelled. Terminating"
        fi
    else
        echo "Deployment cancelled. Execution terminated."
fi
