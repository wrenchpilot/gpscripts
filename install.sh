#!/usr/bin/env bash

<<<<<<< HEAD
cp -av getpw gpcheck gplogin /usr/local/bin
=======
# Detect Homebrew prefix
if command -v brew >/dev/null 2>&1; then
    HOMEBREW_PREFIX="$(brew --prefix)"
else
    echo "Homebrew not found. Please install Homebrew first." >&2
    exit 1
fi

TARGET_BIN="$HOMEBREW_PREFIX/bin"

# Make scripts executable
chmod +x gpstatus gplogin gpdisconnect gpupdatepw

# Copy all scripts
cp -av gpstatus gplogin gpdisconnect gpupdatepw "$TARGET_BIN"
echo "Installed scripts to $TARGET_BIN"

echo ""
echo "=== GlobalProtect Scripts Installation Complete ==="
echo ""
echo "Available commands:"
echo "  gpstatus       - Check VPN connection status"
echo "  gplogin        - Login to GlobalProtect VPN"
echo "  gpdisconnect   - Disconnect from VPN"
echo "  gpupdatepw     - Update username/password in keychain"
echo ""

# Handle keychain setup
keychain="GlobalProtect"
username_keychain="GlobalProtect-Username"

# Prompt for username configuration
echo "=== Username Configuration ==="
echo "Default username: ${USER}"
echo ""
read -p "Enter GlobalProtect username (press Enter to use '${USER}'): " custom_username

if [[ -z "$custom_username" ]]; then
    account="${USER}"
    echo "Using system username: $account"
else
    account="$custom_username"
    echo "Using custom username: $account"
fi

echo ""

# Check if password exists in keychain
if security find-generic-password -a "$account" -s "$keychain" >/dev/null 2>&1; then
    echo "✅ GlobalProtect password already exists in keychain."
    password_exists=true
else
    echo "⚠️  GlobalProtect password not found in keychain."
    password_exists=false
fi

# Check if username is stored in keychain
if security find-generic-password -a "$account" -s "$username_keychain" >/dev/null 2>&1; then
    stored_username=$(security find-generic-password -a "$account" -s "$username_keychain" -w 2>/dev/null)
    if [[ "$stored_username" == "$account" ]]; then
        echo "✅ Username configuration already stored in keychain."
        username_exists=true
    else
        echo "⚠️  Different username found in keychain, will update."
        username_exists=false
    fi
else
    echo "⚠️  Username configuration not found in keychain."
    username_exists=false
fi

# Set up password if needed
if [[ "$password_exists" == false ]]; then
    echo ""
    echo "Setting up password storage in macOS keychain..."
    echo "Service: $keychain"
    echo "Account: $account"
    echo ""
    
    # Prompt for password
    echo "Please enter your GlobalProtect password:"
    read -s -p "Password: " password
    echo ""
    
    if [[ -z "$password" ]]; then
        echo "❌ No password entered. You can set this up later manually."
        echo ""
        echo "To add manually later:"
        echo "  security add-generic-password -a \"$account\" -s \"$keychain\" -w \"YOUR_PASSWORD\""
    else
        # Add password to keychain
        if security add-generic-password -a "$account" -s "$keychain" -w "$password" 2>/dev/null; then
            echo "✅ Password stored successfully in keychain!"
        else
            echo "❌ Failed to store password in keychain."
            echo "You may need to grant permission or add it manually:"
            echo "  security add-generic-password -a \"$account\" -s \"$keychain\" -w \"YOUR_PASSWORD\""
        fi
    fi
fi

# Set up username storage if needed
if [[ "$username_exists" == false ]]; then
    echo ""
    echo "Storing username configuration in keychain..."
    
    # Store username in keychain for retrieval by gplogin
    if security add-generic-password -a "$account" -s "$username_keychain" -w "$account" 2>/dev/null; then
        echo "✅ Username stored successfully in keychain!"
    else
        echo "❌ Failed to store username in keychain."
        echo "gplogin will fall back to system username if needed."
    fi
fi

echo ""
echo "Installation complete! All scripts are ready to use."
>>>>>>> 8fc3ac2 (feat: Complete overhaul of GlobalProtect automation with enhanced security and usability)
