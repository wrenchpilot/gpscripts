#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${USER:-$(id -un)}"

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install Homebrew first." >&2
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 is required to safely encode the keychain configuration." >&2
    exit 1
fi

HOMEBREW_PREFIX="$(brew --prefix)"
TARGET_BIN="$HOMEBREW_PREFIX/bin"
mkdir -p "$TARGET_BIN"

for script in gpstatus gplogin gpdisconnect gpupdatepw; do
    install -m 755 "$SCRIPT_DIR/$script" "$TARGET_BIN/$script"
done

echo "Installed scripts to $TARGET_BIN"
echo
echo "=== GlobalProtect Scripts Installation Complete ==="
echo
echo "Available commands:"
echo "  gpstatus       - Check VPN connection status"
echo "  gplogin        - Login to GlobalProtect VPN"
echo "  gpdisconnect   - Disconnect from VPN"
echo "  gpupdatepw     - Update username/password in keychain"
echo

keychain="GlobalProtect"
config_keychain="GlobalProtect-Config"

# Configuration is keyed by the macOS account so gplogin can find it even
# when the VPN username differs from the local account name.
echo "=== Username Configuration ==="
echo "Default username: ${CURRENT_USER}"
echo
read -r -p "Enter GlobalProtect username (press Enter to use '${CURRENT_USER}'): " custom_username
account="${custom_username:-$CURRENT_USER}"
if [[ -n "$custom_username" ]]; then
    echo "Using custom username: $account"
else
    echo "Using system username: $account"
fi

echo
echo "=== Portal URL Configuration ==="
echo "Enter just the domain (e.g., vpn.company.com), no protocol needed."
echo "The URL is saved in the configuration; GlobalProtect may still require manual setup."
echo
read -r -p "Enter GlobalProtect portal URL (press Enter to skip): " portal_url

if [[ -n "$portal_url" ]]; then
    echo "Portal URL configured: $portal_url"
else
    echo "No portal URL configured."
fi

echo
if security find-generic-password -a "$account" -s "$keychain" >/dev/null 2>&1; then
    echo "GlobalProtect password already exists in keychain for '$account'."
else
    echo "A GlobalProtect password is not yet stored for '$account'."
    echo "Enter it at the secure Keychain prompt (the password is not passed as a command-line argument)."
    if security add-generic-password -a "$account" -s "$keychain" -w; then
        echo "Password stored successfully in keychain."
    else
        echo "Failed to store the password. You can add it later with:"
        echo "  security add-generic-password -a \"$account\" -s \"$keychain\" -w"
    fi
fi

config_json="$(python3 -c 'import json, sys; print(json.dumps({"username": sys.argv[1], "portal_url": sys.argv[2]}))' "$account" "$portal_url")"
echo
if security add-generic-password -U -a "$CURRENT_USER" -s "$config_keychain" -w "$config_json"; then
    echo "Configuration stored in keychain for macOS account '$CURRENT_USER'."
else
    echo "Failed to store GlobalProtect configuration in keychain." >&2
    exit 1
fi

echo
echo "Installation complete! All scripts are ready to use."
