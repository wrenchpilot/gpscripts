#!/usr/bin/env bash

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
config_keychain="GlobalProtect-Config"

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

# Prompt for portal URL configuration
echo "=== Portal URL Configuration ==="
echo "If GlobalProtect doesn't have the portal URL pre-filled, you can configure it here."
echo "Enter just the domain (e.g., vpn.company.com), no protocol needed."
echo ""
read -p "Enter GlobalProtect portal URL (press Enter to skip): " portal_url

if [[ -n "$portal_url" ]]; then
    echo "Portal URL configured: $portal_url"
else
    echo "No portal URL configured - will use whatever is in the app"
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

# Check if configuration exists in keychain
if security find-generic-password -a "$account" -s "$config_keychain" >/dev/null 2>&1; then
    stored_config=$(security find-generic-password -a "$account" -s "$config_keychain" -w 2>/dev/null)
    echo "✅ Configuration found in keychain."
    config_exists=true
else
    echo "⚠️  Configuration not found in keychain."
    config_exists=false
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
if [[ "$config_exists" == false ]]; then
    echo ""
    echo "Storing configuration in keychain..."
    
    # Create JSON configuration
    config_json="{\"username\":\"$account\""
    if [[ -n "$portal_url" ]]; then
        config_json+=",\"portal_url\":\"$portal_url\""
    fi
    config_json+="}"
    
    # Store configuration in keychain
    if security add-generic-password -a "$account" -s "$config_keychain" -w "$config_json" 2>/dev/null; then
        echo "✅ Configuration stored successfully in keychain!"
    else
        echo "❌ Failed to store configuration in keychain."
        echo "gplogin will fall back to system username if needed."
    fi
fi

echo ""
echo "Installation complete! All scripts are ready to use."
