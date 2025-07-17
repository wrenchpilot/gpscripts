#!/usr/bin/env bash

# Detect Homebrew prefix
if command -v brew >/dev/null 2>&1; then
    HOMEBREW_PREFIX="$(brew --prefix)"
else
    echo "Homebrew not found. Using default /usr/local" >&2
    HOMEBREW_PREFIX="/usr/local"
fi

TARGET_BIN="$HOMEBREW_PREFIX/bin"

echo "Removing GlobalProtect scripts from $TARGET_BIN..."

# Remove current scripts
rm -rf "$TARGET_BIN/gplogin"
rm -rf "$TARGET_BIN/gpstatus"
rm -rf "$TARGET_BIN/gpdisconnect"
rm -rf "$TARGET_BIN/gpupdatepw"

# Clean up old script names from previous versions
echo "Cleaning up old script names from previous versions..."
rm -rf "$TARGET_BIN/gpcheck"  # Old name for gpstatus
rm -rf "$TARGET_BIN/getpw-setup"  # Removed in favor of integrated install setup

# Clean up keychain entries
echo ""
echo "Cleaning up keychain entries..."

# Try to get the username from the config first
CONFIG_JSON=$(security find-generic-password -s "GlobalProtect-Config" -w 2>/dev/null || echo "")
if [ -n "$CONFIG_JSON" ]; then
    USERNAME=$(echo "$CONFIG_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('username', ''))" 2>/dev/null || echo "")
fi

# If we couldn't get username from config, try to find it from the password entry
if [ -z "$USERNAME" ]; then
    USERNAME=$(security find-generic-password -s "GlobalProtect" -g 2>&1 | grep "acct" | cut -d'"' -f4 2>/dev/null || echo "")
fi

# Remove keychain entries if we found a username
if [ -n "$USERNAME" ]; then
    echo "Removing keychain entries for user: $USERNAME"
    
    # Remove password entry
    if security delete-generic-password -a "$USERNAME" -s "GlobalProtect" >/dev/null 2>&1; then
        echo "  ✓ Removed GlobalProtect password"
    else
        echo "  ⚠ No GlobalProtect password found (or already removed)"
    fi
    
    # Remove config entry
    if security delete-generic-password -a "$USERNAME" -s "GlobalProtect-Config" >/dev/null 2>&1; then
        echo "  ✓ Removed GlobalProtect configuration"
    else
        echo "  ⚠ No GlobalProtect configuration found (or already removed)"
    fi
    
    # Clean up old entries from previous versions
    if security delete-generic-password -a "$USERNAME" -s "GlobalProtect-Username" >/dev/null 2>&1; then
        echo "  ✓ Removed legacy GlobalProtect-Username entry"
    fi
    
    if security delete-generic-password -a "$USERNAME" -s "GlobalProtect-Portal" >/dev/null 2>&1; then
        echo "  ✓ Removed legacy GlobalProtect-Portal entry"
    fi
else
    echo "  ⚠ Could not determine username from keychain entries"
    echo "  To manually remove keychain entries, run:"
    echo "    security delete-generic-password -a \"YOUR_USERNAME\" -s \"GlobalProtect\""
    echo "    security delete-generic-password -a \"YOUR_USERNAME\" -s \"GlobalProtect-Config\""
fi

echo ""
echo "Scripts removed successfully."
echo ""
echo "Uninstall complete."
