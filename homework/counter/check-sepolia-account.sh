#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ACCOUNT_ADDRESS="0x0620b4d7847dece1855e70dedc9ac7501b11f41295368aaf8f09ec531c5b87a4"
NETWORK="sepolia"

echo -e "${GREEN}=== Sepolia Account Status ===${NC}"
echo ""
echo "Account Address: $ACCOUNT_ADDRESS"
echo ""

# Check balance
echo -e "${YELLOW}Checking balance...${NC}"
BALANCE=$(starkli balance $ACCOUNT_ADDRESS --network $NETWORK 2>&1)
echo "Balance: $BALANCE ETH"

# Check if account is deployed
echo ""
echo -e "${YELLOW}Checking deployment status...${NC}"
starkli account fetch $ACCOUNT_ADDRESS --network $NETWORK &> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Account is deployed${NC}"
else
    echo -e "${RED}✗ Account is not deployed${NC}"
    echo ""
    if [[ "$BALANCE" == "0.000000000000000000" ]]; then
        echo "Next steps:"
        echo "1. Fund your account using one of these faucets:"
        echo "   - https://faucet.starknet.io/"
        echo "   - https://www.alchemy.com/faucets/starknet-sepolia"
        echo "   - https://blastapi.io/faucets/starknet-sepolia-eth"
        echo ""
        echo "2. Once funded, run: ./deploy-sepolia.sh"
    else
        echo "Account has funds but is not deployed."
        echo "Run: ./deploy-sepolia.sh to deploy the account and contract"
    fi
fi

echo ""
echo "Useful links:"
echo "View on Voyager: https://sepolia.voyager.online/contract/$ACCOUNT_ADDRESS"
echo "View on Starkscan: https://sepolia.starkscan.co/contract/$ACCOUNT_ADDRESS"