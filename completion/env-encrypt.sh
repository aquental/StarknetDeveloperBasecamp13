#!/bin/bash

# Script for managing encrypted .env files with GPG

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Function to encrypt .env file
encrypt_env() {
    if [ ! -f .env ]; then
        print_msg "Error: .env file not found!" "$RED"
        exit 1
    fi
    
    print_msg "Encrypting .env file..." "$YELLOW"
    
    # Remove old encrypted file if exists
    [ -f .env.gpg ] && rm .env.gpg
    
    # Encrypt with symmetric key (password)
    gpg --symmetric --cipher-algo AES256 --output .env.gpg .env
    
    if [ $? -eq 0 ]; then
        print_msg "✓ Successfully encrypted to .env.gpg" "$GREEN"
        print_msg "You can now safely delete .env if desired" "$YELLOW"
    else
        print_msg "Error: Encryption failed!" "$RED"
        exit 1
    fi
}

# Function to decrypt .env.gpg file
decrypt_env() {
    if [ ! -f .env.gpg ]; then
        print_msg "Error: .env.gpg file not found!" "$RED"
        exit 1
    fi
    
    if [ -f .env ]; then
        print_msg "Warning: .env already exists. Overwrite? (y/n)" "$YELLOW"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_msg "Decryption cancelled." "$YELLOW"
            exit 0
        fi
    fi
    
    print_msg "Decrypting .env.gpg file..." "$YELLOW"
    
    # Decrypt the file
    gpg --decrypt --output .env .env.gpg
    
    if [ $? -eq 0 ]; then
        print_msg "✓ Successfully decrypted to .env" "$GREEN"
        # Set restrictive permissions on decrypted file
        chmod 600 .env
        print_msg "✓ Set restrictive permissions (600) on .env" "$GREEN"
    else
        print_msg "Error: Decryption failed!" "$RED"
        exit 1
    fi
}

# Function to view encrypted content without creating .env file
view_env() {
    if [ ! -f .env.gpg ]; then
        print_msg "Error: .env.gpg file not found!" "$RED"
        exit 1
    fi
    
    print_msg "Viewing encrypted .env content (will not save to disk):" "$YELLOW"
    echo "----------------------------------------"
    gpg --decrypt .env.gpg 2>/dev/null
    echo "----------------------------------------"
}

# Function to edit encrypted .env file
edit_env() {
    if [ ! -f .env.gpg ]; then
        print_msg "Error: .env.gpg file not found!" "$RED"
        exit 1
    fi
    
    # Create temporary file
    TMPFILE=$(mktemp)
    trap "rm -f $TMPFILE" EXIT
    
    print_msg "Decrypting for editing..." "$YELLOW"
    
    # Decrypt to temporary file
    gpg --decrypt --output "$TMPFILE" .env.gpg
    
    if [ $? -ne 0 ]; then
        print_msg "Error: Decryption failed!" "$RED"
        exit 1
    fi
    
    # Edit the file
    ${EDITOR:-vi} "$TMPFILE"
    
    print_msg "Re-encrypting file..." "$YELLOW"
    
    # Re-encrypt
    gpg --symmetric --cipher-algo AES256 --output .env.gpg.new "$TMPFILE"
    
    if [ $? -eq 0 ]; then
        mv .env.gpg.new .env.gpg
        print_msg "✓ Successfully updated encrypted .env.gpg" "$GREEN"
    else
        print_msg "Error: Re-encryption failed!" "$RED"
        rm -f .env.gpg.new
        exit 1
    fi
}

# Main menu
show_menu() {
    echo ""
    print_msg "=== GPG .env File Manager ===" "$GREEN"
    echo "1) Encrypt .env to .env.gpg"
    echo "2) Decrypt .env.gpg to .env"
    echo "3) View encrypted content (without saving)"
    echo "4) Edit encrypted .env.gpg"
    echo "5) Exit"
    echo ""
    echo -n "Choose an option: "
}

# Parse command line arguments
if [ $# -eq 1 ]; then
    case $1 in
        encrypt)
            encrypt_env
            ;;
        decrypt)
            decrypt_env
            ;;
        view)
            view_env
            ;;
        edit)
            edit_env
            ;;
        *)
            print_msg "Usage: $0 [encrypt|decrypt|view|edit]" "$YELLOW"
            print_msg "Or run without arguments for interactive menu" "$YELLOW"
            exit 1
            ;;
    esac
else
    # Interactive menu
    while true; do
        show_menu
        read -r choice
        case $choice in
            1) encrypt_env ;;
            2) decrypt_env ;;
            3) view_env ;;
            4) edit_env ;;
            5) 
                print_msg "Goodbye!" "$GREEN"
                exit 0 
                ;;
            *) 
                print_msg "Invalid option!" "$RED"
                ;;
        esac
    done
fi