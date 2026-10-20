#!/usr/bin/env bash

CURRENT_USER="${USER:-$(id -un)}"

# Detect the install prefix. If Homebrew has been removed, prefer whichever
# known prefix still contains one of these scripts. Never fall back to /bin
# when `brew --prefix` fails.
HOMEBREW_PREFIX=""
if command -v brew >/dev/null 2>&1; then
    HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
fi
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ -e /opt/homebrew/bin/gplogin || -e /opt/homebrew/bin/gpstatus ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    elif [[ -e /usr/local/bin/gplogin || -e /usr/local/bin/gpstatus ]]; then
        HOMEBREW_PREFIX="/usr/local"
    else
        echo "Could not locate the Homebrew installation or installed scripts; nothing removed." >&2
        exit 1
    fi
fi
if [[ "$HOMEBREW_PREFIX" == "/" ]]; then
    echo "Invalid Homebrew prefix '/'; refusing to remove files from /bin." >&2
    exit 1
fi

TARGET_BIN="$HOMEBREW_PREFIX/bin"
echo "Removing GlobalProtect scripts from $TARGET_BIN..."
for script in gplogin gpstatus gpdisconnect gpupdatepw gpcheck getpw-setup; do
    rm -f "$TARGET_BIN/$script"
done

# Find the configured VPN username. New versions key config by the local
# account; older versions used the VPN username as the Keychain account.
CONFIG_JSON="$(security find-generic-password -a "$CURRENT_USER" -s "GlobalProtect-Config" -w 2>/dev/null || true)"
if [[ -z "$CONFIG_JSON" ]]; then
    CONFIG_JSON="$(security find-generic-password -s "GlobalProtect-Config" -w 2>/dev/null || true)"
fi

USERNAME=""
if [[ -n "$CONFIG_JSON" ]] && command -v python3 >/dev/null 2>&1; then
    USERNAME="$(printf '%s' "$CONFIG_JSON" | python3 -c 'import json, sys; value = json.load(sys.stdin).get("username", ""); print(value if isinstance(value, str) else "")' 2>/dev/null || true)"
fi
if [[ -z "$USERNAME" ]]; then
    USERNAME="$(security find-generic-password -s "GlobalProtect" -g 2>&1 | grep "acct" | cut -d'"' -f4 2>/dev/null || true)"
fi

# Config entries are keyed by the local account in new installs, or by the
# VPN username in older installs. Clean up both; remove the password only for
# the configured VPN username.
if [[ -n "$USERNAME" ]]; then
    echo "Removing keychain entries for VPN user: $USERNAME"
    if security delete-generic-password -a "$USERNAME" -s "GlobalProtect" >/dev/null 2>&1; then
        echo "  Removed GlobalProtect password"
    else
        echo "  No GlobalProtect password found (or already removed)"
    fi
else
    echo "Could not determine the configured VPN username; leaving password entries untouched."
    echo "To remove one manually: security delete-generic-password -a \"YOUR_USERNAME\" -s \"GlobalProtect\""
fi

for account in "$CURRENT_USER" "$USERNAME"; do
    [[ -n "$account" ]] || continue
    if [[ "$account" == "${previous_account:-}" ]]; then
        continue
    fi
    previous_account="$account"

    if security delete-generic-password -a "$account" -s "GlobalProtect-Config" >/dev/null 2>&1; then
        echo "  Removed GlobalProtect configuration for '$account'"
    fi
    security delete-generic-password -a "$account" -s "GlobalProtect-Username" >/dev/null 2>&1 || true
    security delete-generic-password -a "$account" -s "GlobalProtect-Portal" >/dev/null 2>&1 || true
done

echo
echo "Scripts removed successfully."
echo "Uninstall complete."
