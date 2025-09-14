#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starknet Counter Contract Mainnet Deployment Script ===${NC}"
echo -e "${RED}⚠️  WARNING: This will deploy to MAINNET and use real ETH!${NC}"
echo ""

# Configuration
KEYSTORE_PATH="$HOME/.starkli-wallets/mainnet-keystore.json"
ACCOUNT_PATH="$HOME/.starkli-wallets/account.json"
NETWORK="mainnet"
ACCOUNT_ADDRESS="0x06cbB71892BDe5d50AB0F2b373335820376Ed4cBAe697f8cfe89cd52C1B40ecF"

# Check if keystore exists
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}Error: Mainnet keystore not found at $KEYSTORE_PATH${NC}"
    echo ""
    echo "To create a keystore for your mainnet account:"
    echo "1. Export your private key from Argent X wallet"
    echo "2. Run: starkli signer keystore from-key $KEYSTORE_PATH"
    echo "3. Enter your private key when prompted"
    echo "4. Set a password for the keystore"
    exit 1
fi

# Confirmation prompt
echo -e "${YELLOW}You are about to deploy to MAINNET!${NC}"
echo "Account: $ACCOUNT_ADDRESS"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 1: Check balance
echo ""
echo -e "${YELLOW}Step 1: Checking account balance...${NC}"
BALANCE=$(starkli balance $ACCOUNT_ADDRESS --network $NETWORK 2>&1)
echo "Current balance: $BALANCE ETH"

# Convert balance to number for comparison (rough check)
BALANCE_NUM=$(echo $BALANCE | sed 's/0\.//' | sed 's/^0*//')
if [ -z "$BALANCE_NUM" ] || [ "$BALANCE_NUM" = "000000000000000000" ]; then
    echo -e "${RED}Error: Insufficient balance for deployment!${NC}"
    echo "Please ensure your account has enough ETH for gas fees."
    exit 1
fi

# Step 2: Build the contract
echo ""
echo -e "${YELLOW}Step 2: Building the contract...${NC}"
cd "$(dirname "$0")"
scarb build
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build contract${NC}"
    exit 1
fi
echo -e "${GREEN}Contract built successfully!${NC}"

# Step 3: Estimate fees
echo ""
echo -e "${YELLOW}Step 3: Estimating declaration fee...${NC}"
DECLARE_FEE=$(starkli declare target/dev/counter_Counter.contract_class.json \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH \
    --compiler-version 2.12.1 \
    --estimate-only 2>&1)

echo "Estimated declaration fee: $DECLARE_FEE"
echo ""
read -p "Do you want to proceed with declaration? (yes/no): " proceed_declare

if [ "$proceed_declare" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 4: Declare the contract
echo ""
echo -e "${YELLOW}Step 4: Declaring the contract...${NC}"
DECLARE_OUTPUT=$(starkli declare target/dev/counter_Counter.contract_class.json \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH \
    --compiler-version 2.12.1 2>&1)

echo "$DECLARE_OUTPUT"

# Check if contract was already declared
if echo "$DECLARE_OUTPUT" | grep -q "already been declared"; then
    echo -e "${CYAN}Contract class already declared, extracting class hash...${NC}"
    CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep -oE "0x[0-9a-fA-F]{64}" | head -1)
else
    # Extract class hash from successful declaration
    CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep -oE "0x[0-9a-fA-F]{64}" | head -1)
fi

if [ -z "$CLASS_HASH" ]; then
    echo -e "${RED}Failed to extract class hash${NC}"
    echo "Declaration output: $DECLARE_OUTPUT"
    exit 1
fi

echo -e "${GREEN}Contract class hash: $CLASS_HASH${NC}"

# Step 5: Deploy the contract instance
echo ""
echo -e "${YELLOW}Step 5: Deploying the contract instance...${NC}"
echo "Initial counter value: 0"
echo "Owner address: $ACCOUNT_ADDRESS"

# Estimate deployment fee
echo "Estimating deployment fee..."
DEPLOY_FEE=$(starkli deploy $CLASS_HASH 0 $ACCOUNT_ADDRESS \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH \
    --estimate-only 2>&1)

echo "Estimated deployment fee: $DEPLOY_FEE"
echo ""
read -p "Do you want to proceed with deployment? (yes/no): " proceed_deploy

if [ "$proceed_deploy" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

DEPLOY_OUTPUT=$(starkli deploy $CLASS_HASH 0 $ACCOUNT_ADDRESS \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH 2>&1)

echo "$DEPLOY_OUTPUT"

# Extract contract address
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE "0x[0-9a-fA-F]{64}" | tail -1)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo -e "${RED}Failed to extract contract address${NC}"
    exit 1
fi

# Save deployment info
echo ""
echo -e "${GREEN}=== Deployment Successful! ===${NC}"
echo "Class Hash: $CLASS_HASH"
echo "Contract Address: $CONTRACT_ADDRESS"

# Save deployment info to file
DEPLOYMENT_FILE="mainnet-deployment.json"
cat > $DEPLOYMENT_FILE << EOF
{
  "network": "mainnet",
  "class_hash": "$CLASS_HASH",
  "contract_address": "$CONTRACT_ADDRESS",
  "deployment_date": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "initial_value": 0,
  "owner": "$ACCOUNT_ADDRESS",
  "account": "$ACCOUNT_ADDRESS"
}
EOF

echo ""
echo "Deployment info saved to: $DEPLOYMENT_FILE"
echo ""
echo "You can now interact with your contract:"
echo "  Read counter:  starkli call $CONTRACT_ADDRESS get_counter --network $NETWORK"
echo "  Increment:     starkli invoke $CONTRACT_ADDRESS increment --network $NETWORK --keystore $KEYSTORE_PATH --account $ACCOUNT_PATH"
echo "  Decrement:     starkli invoke $CONTRACT_ADDRESS decrement --network $NETWORK --keystore $KEYSTORE_PATH --account $ACCOUNT_PATH"
echo ""
echo -e "${CYAN}View on block explorers:${NC}"
echo "Voyager:   https://voyager.online/contract/$CONTRACT_ADDRESS"
echo "Starkscan: https://starkscan.co/contract/$CONTRACT_ADDRESS"
echo "StarkCompass: https://starkcompass.com/contract/$CONTRACT_ADDRESS"