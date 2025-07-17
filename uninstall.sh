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

echo ""
echo "Scripts removed successfully."
echo ""
echo "Note: Your GlobalProtect keychain entries were NOT removed."
echo "To remove them manually, run:"
echo "  security delete-generic-password -a \"YOUR_USERNAME\" -s \"GlobalProtect\""
echo "  security delete-generic-password -a \"YOUR_USERNAME\" -s \"GlobalProtect-Username\""

echo ""
echo "Uninstall complete."
