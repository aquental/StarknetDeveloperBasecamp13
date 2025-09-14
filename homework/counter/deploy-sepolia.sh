#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starknet Counter Contract Deployment Script ===${NC}"
echo ""

# Configuration
KEYSTORE_PATH="$HOME/.starkli-wallets/sepolia-keystore.json"
ACCOUNT_PATH="$HOME/.starkli-wallets/sepolia-account.json"
NETWORK="sepolia"
ACCOUNT_ADDRESS="0x0620b4d7847dece1855e70dedc9ac7501b11f41295368aaf8f09ec531c5b87a4"

# Step 1: Check balance
echo -e "${YELLOW}Step 1: Checking account balance...${NC}"
BALANCE=$(starkli balance $ACCOUNT_ADDRESS --network $NETWORK 2>&1)
echo "Current balance: $BALANCE ETH"

if [[ "$BALANCE" == "0.000000000000000000" ]]; then
    echo -e "${RED}Error: Account has no funds!${NC}"
    echo "Please fund your account at: https://faucet.starknet.io/"
    echo "Address: $ACCOUNT_ADDRESS"
    exit 1
fi

# Step 2: Deploy account (if not already deployed)
echo -e "${YELLOW}Step 2: Checking if account is deployed...${NC}"
starkli account fetch $ACCOUNT_ADDRESS --network $NETWORK &> /dev/null
if [ $? -ne 0 ]; then
    echo "Account not deployed. Deploying now..."
    starkli account deploy $ACCOUNT_PATH --network $NETWORK --keystore $KEYSTORE_PATH
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to deploy account${NC}"
        exit 1
    fi
    echo -e "${GREEN}Account deployed successfully!${NC}"
else
    echo "Account already deployed."
fi

# Step 3: Build the contract
echo -e "${YELLOW}Step 3: Building the contract...${NC}"
cd "$(dirname "$0")"
scarb build
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build contract${NC}"
    exit 1
fi
echo -e "${GREEN}Contract built successfully!${NC}"

# Step 4: Declare the contract
echo -e "${YELLOW}Step 4: Declaring the contract...${NC}"
DECLARE_OUTPUT=$(starkli declare target/dev/counter_Counter.contract_class.json \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH \
    --compiler-version 2.12.1 2>&1)

echo "$DECLARE_OUTPUT"

# Extract class hash from output
CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep -o "0x[0-9a-fA-F]*" | head -1)

if [ -z "$CLASS_HASH" ]; then
    echo -e "${RED}Failed to extract class hash${NC}"
    echo "Declaration output: $DECLARE_OUTPUT"
    exit 1
fi

echo -e "${GREEN}Contract declared with class hash: $CLASS_HASH${NC}"

# Step 5: Deploy the contract
echo -e "${YELLOW}Step 5: Deploying the contract instance...${NC}"
echo "Deploying with initial counter value: 0"

DEPLOY_OUTPUT=$(starkli deploy $CLASS_HASH \
    --constructor-calldata 0 \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH 2>&1)

echo "$DEPLOY_OUTPUT"

# Extract contract address
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "0x[0-9a-fA-F]*" | tail -1)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo -e "${RED}Failed to extract contract address${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Deployment Successful! ===${NC}"
echo "Class Hash: $CLASS_HASH"
echo "Contract Address: $CONTRACT_ADDRESS"
echo ""
echo "You can now interact with your contract:"
echo "  Read counter:  starkli call $CONTRACT_ADDRESS get_counter --network $NETWORK"
echo "  Increment:     starkli invoke $CONTRACT_ADDRESS increment --network $NETWORK --keystore $KEYSTORE_PATH --account $ACCOUNT_PATH"
echo "  Decrement:     starkli invoke $CONTRACT_ADDRESS decrement --network $NETWORK --keystore $KEYSTORE_PATH --account $ACCOUNT_PATH"
echo ""
echo "View on Voyager: https://sepolia.voyager.online/contract/$CONTRACT_ADDRESS"
echo "View on Starkscan: https://sepolia.starkscan.co/contract/$CONTRACT_ADDRESS"