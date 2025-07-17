# GlobalProtect Automation Scripts for macOS

A collection of command-line tools to automate GlobalProtect VPN operations on macOS using a hybrid approach: system-level commands for reliable status checking and minimal AppleScript for authentication.

## Quick Start

### Prerequisites

- **macOS** with Homebrew installed
- **GlobalProtect VPN client** installed and configured
- **Duo 2FA** configured
- **Yubikey** (optional, preferred for 2FA - falls back to Duo Push if not present)

### Installation

```bash
git clone <this-repo>
cd gpscripts
./install.sh
```

The install script will:

- Detect your Homebrew installation (`/opt/homebrew` or `/usr/local`)
- Copy all scripts to the appropriate `bin` directory
- Set up secure password storage in macOS keychain
- Make scripts available system-wide

### Basic Usage

```bash
gpstatus              # Check VPN connection status
gplogin               # Connect to VPN with auto 2FA
gpdisconnect          # Disconnect from VPN
gpupdatepw            # Update username/password in keychain
```

### Uninstall

```bash
./uninstall.sh
```

## Overview

These scripts provide automation for Palo Alto Networks GlobalProtect VPN client on macOS. Since GlobalProtect doesn't provide command-line authentication tools on macOS, the scripts use:

- **System-level commands** (`route`, `ifconfig`, `launchctl`) for reliable VPN status detection and service management
- **Minimal AppleScript** only where necessary for authentication UI interaction (since no CLI alternative exists)

## Scripts

### 📡 `gpstatus` - VPN Connection Status

Checks if GlobalProtect VPN is connected using native macOS networking tools.

**Usage:**

```bash
gpstatus              # Show detailed VPN status
gpstatus --help       # Show help
```

**Output Example:**

```
=== GlobalProtect VPN Status ===
GlobalProtect GUI service (pangpa): loaded
GlobalProtect VPN service (pangps): loaded

✅ VPN is CONNECTED
   Interface: utun4
   VPN IP: 10.2.242.94
   Gateway: 10.2.242.94
   MTU: 1280
```

**Exit Codes:**

- `0` - VPN is connected
- `1` - VPN is not connected

### 🔐 `gplogin` - Automated VPN Login

Automates GlobalProtect login with Duo 2FA support (Yubikey preferred, push fallback).

**Usage:**

```bash
gplogin               # Connect to VPN with auto 2FA
gplogin --help        # Show help
```

**Features:**

- Automatic Yubikey detection (preferred method)
- Fallback to Duo Push notifications
- Smart service management (doesn't restart running services)
- Waits for authentication completion

**Requirements:**

- GlobalProtect app installed and configured
- Duo 2FA configured (for automated login)
- macOS keychain access (set up automatically)

### 🔌 `gpdisconnect` - Clean VPN Disconnect

Disconnects from GlobalProtect VPN without killing the menu bar application.

**Usage:**

```bash
gpdisconnect          # Disconnect from VPN
gpdisconnect --help   # Show help
```

### 🔑 `gpupdatepw` - Update Credentials

Updates the username and/or password stored in the macOS keychain. Useful when credentials change or if you need to reconfigure the username.

**Features:**

- Update username only, password only, or both
- Interactive prompts for new credentials
- Validates keychain operations
- Handles username changes with automatic password migration

**Usage:**

```bash
gpupdatepw            # Update both username and password
gpupdatepw -u         # Update only username
gpupdatepw -p         # Update only password
gpupdatepw --help     # Show help
```

## Compatibility

- **macOS Version:** 10.15+ (tested on recent versions)
- **Architecture:** Intel and Apple Silicon Macs
- **Homebrew:** Both `/usr/local` and `/opt/homebrew` installations
- **GlobalProtect:** Recent versions with launchctl service management

## Security Considerations

- Passwords are stored securely in macOS keychain.
- No credentials stored in scripts
- Minimal privilege requirements
- Service management uses standard macOS tools

## License

These scripts are provided as-is for automation purposes. Ensure compliance with your organization's IT policies before use.
