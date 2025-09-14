#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Mainnet Keystore Setup ===${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo "1. Never share your private key with anyone"
echo "2. Make sure you're in a secure environment"
echo "3. The keystore will be encrypted with a password you choose"
echo ""

KEYSTORE_PATH="$HOME/.starkli-wallets/mainnet-keystore.json"
ACCOUNT_ADDRESS="0x06cbB71892BDe5d50AB0F2b373335820376Ed4cBAe697f8cfe89cd52C1B40ecF"

if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${CYAN}Keystore already exists at: $KEYSTORE_PATH${NC}"
    read -p "Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo -e "${YELLOW}Steps to export your private key from Argent X:${NC}"
echo "1. Open Argent X browser extension"
echo "2. Click on the three dots menu (⋮) in the top right"
echo "3. Go to 'Settings'"
echo "4. Click on your account name"
echo "5. Click 'Export Private Key'"
echo "6. Enter your password"
echo "7. Copy the private key (it starts with 0x)"
echo ""
echo -e "${RED}Make sure no one can see your screen!${NC}"
echo ""
read -p "Press Enter when you have your private key ready..."

echo ""
echo "Creating keystore..."
starkli signer keystore from-key $KEYSTORE_PATH

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Keystore created successfully!${NC}"
    echo "Location: $KEYSTORE_PATH"
    echo ""
    echo "Verifying keystore with your account..."
    
    # Extract public key from keystore to verify
    echo "Enter your keystore password to verify:"
    PUBLIC_KEY=$(starkli signer keystore inspect $KEYSTORE_PATH 2>/dev/null | grep "Public key:" | cut -d' ' -f3)
    
    if [ ! -z "$PUBLIC_KEY" ]; then
        echo "Keystore public key: $PUBLIC_KEY"
        echo ""
        echo -e "${GREEN}Setup complete! You can now run:${NC}"
        echo "./deploy-mainnet.sh"
    else
        echo -e "${YELLOW}Could not verify keystore, but it was created.${NC}"
        echo "You can proceed with deployment."
    fi
else
    echo ""
    echo -e "${RED}Failed to create keystore${NC}"
    echo "Please check the error message above and try again."
    exit 1
fi

echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "1. Run: ./deploy-mainnet.sh"
echo "2. The script will estimate fees before each transaction"
echo "3. You'll be asked to confirm before spending any ETH"
echo ""
echo -e "${YELLOW}Current mainnet balance:${NC}"
starkli balance $ACCOUNT_ADDRESS --network mainnet