#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Mainnet Deployment Cost Estimator ===${NC}"
echo ""

# Configuration
KEYSTORE_PATH="$HOME/.starkli-wallets/mainnet-keystore.json"
ACCOUNT_PATH="$HOME/.starkli-wallets/account.json"
NETWORK="mainnet"
ACCOUNT_ADDRESS="0x06cbB71892BDe5d50AB0F2b373335820376Ed4cBAe697f8cfe89cd52C1B40ecF"

# Check if keystore exists
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}Error: Mainnet keystore not found${NC}"
    echo "Please run: ./setup-mainnet-keystore.sh first"
    exit 1
fi

# Build the contract first
echo -e "${YELLOW}Building the contract...${NC}"
scarb build
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build contract${NC}"
    exit 1
fi
echo -e "${GREEN}Contract built successfully!${NC}"
echo ""

# Check current balance
echo -e "${CYAN}Current Account Status:${NC}"
echo "Address: $ACCOUNT_ADDRESS"
BALANCE=$(starkli balance $ACCOUNT_ADDRESS --network $NETWORK 2>&1)
echo "Balance: $BALANCE ETH"
echo ""

# Estimate declaration cost
echo -e "${YELLOW}Estimating contract declaration cost...${NC}"
echo "This will NOT execute the transaction, only estimate fees."
echo ""

DECLARE_ESTIMATE=$(starkli declare target/dev/counter_Counter.contract_class.json \
    --network $NETWORK \
    --keystore $KEYSTORE_PATH \
    --account $ACCOUNT_PATH \
    --compiler-version 2.12.1 \
    --estimate-only 2>&1)

# Check if already declared
if echo "$DECLARE_ESTIMATE" | grep -q "already been declared"; then
    echo -e "${CYAN}Contract class is already declared on mainnet!${NC}"
    echo "You can skip declaration and proceed directly to deployment."
    CLASS_HASH=$(echo "$DECLARE_ESTIMATE" | grep -oE "0x[0-9a-fA-F]{64}" | head -1)
    echo "Class Hash: $CLASS_HASH"
    DECLARATION_COST="0 (already declared)"
else
    echo "Declaration fee estimate: $DECLARE_ESTIMATE"
    DECLARATION_COST="$DECLARE_ESTIMATE"
    
    # Try to extract class hash for deployment estimation
    # First, we need to get the class hash without actually declaring
    CLASS_HASH=$(starkli class-hash target/dev/counter_Counter.contract_class.json 2>/dev/null)
fi

echo ""
echo -e "${YELLOW}Estimating contract deployment cost...${NC}"

if [ ! -z "$CLASS_HASH" ]; then
    DEPLOY_ESTIMATE=$(starkli deploy $CLASS_HASH \
        --constructor-calldata 0 \
        --network $NETWORK \
        --keystore $KEYSTORE_PATH \
        --account $ACCOUNT_PATH \
        --estimate-only 2>&1)
    
    echo "Deployment fee estimate: $DEPLOY_ESTIMATE"
else
    echo -e "${YELLOW}Note: Cannot estimate deployment cost until contract is declared${NC}"
    DEPLOY_ESTIMATE="Requires declaration first"
fi

# Summary
echo ""
echo -e "${GREEN}=== Cost Summary ===${NC}"
echo "Declaration: $DECLARATION_COST"
echo "Deployment:  $DEPLOY_ESTIMATE"
echo ""
echo "Current balance: $BALANCE ETH"
echo ""

# Parse balance to check if sufficient
BALANCE_NUM=$(echo $BALANCE | awk '{print $1}' | sed 's/[^0-9.]//g')
if (( $(echo "$BALANCE_NUM > 0.0001" | bc -l) )); then
    echo -e "${GREEN}✅ Balance appears sufficient for deployment${NC}"
    echo ""
    echo "To proceed with actual deployment, run:"
    echo "./deploy-mainnet.sh"
else
    echo -e "${YELLOW}⚠️  Balance might be low for deployment${NC}"
    echo "Consider the gas fees shown above before proceeding."
fi

echo ""
echo -e "${CYAN}Note: Gas prices fluctuate. Actual costs may vary.${NC}"
echo "The deployment script will ask for confirmation before each transaction."