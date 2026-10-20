# GlobalProtect Automation Scripts for macOS

A collection of command-line tools to automate GlobalProtect VPN operations on macOS using a hybrid approach: system-level commands for reliable status checking and minimal AppleScript for authentication.

## Quick Start

### Prerequisites

- **macOS** with Homebrew and Python 3 installed
- **GlobalProtect VPN client** installed and configured
- **Duo 2FA** configured (*Yubikey preferred - Duo Push fallback under testing*)
- **Yubikey** (optional, preferred for 2FA - falls back to Duo Push if not present)

### Installation

```bash
git clone https://github.com/wrenchpilot/gpscripts.git
cd gpscripts
./install.sh
```

The install script will:

- Detect your Homebrew installation (`/opt/homebrew` or `/usr/local`)
- Copy all scripts to the appropriate `bin` directory
- Configure username (defaults to current user, customizable)
- Save an optional portal URL; `gplogin` fills it only when the app exposes a clearly labeled portal field, otherwise configure it in GlobalProtect manually
- Set up secure password storage in macOS keychain
- Store configuration as JSON in keychain for easy management
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

The uninstall script will:

- Remove all scripts from the Homebrew bin directory
- Clean up keychain entries (passwords and configuration)
- Remove any legacy keychain entries from previous versions

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

```text
=== GlobalProtect VPN Status ===
GlobalProtect GUI service (pangpa): loaded
GlobalProtect VPN service (pangps): loaded

✅ GlobalProtect VPN is CONNECTED
   Interface: utun4
   VPN IP: x.x.x.x
   MTU: 1280
```

**Exit Codes:**

- `0` - GlobalProtect's VPN service is loaded and the default route uses an IPv4 `utun` interface
- `1` - No IPv4 `utun` interface was detected
- `2` - A `utun` interface exists but routing or service state cannot confirm GlobalProtect (for example, split tunneling or another utun-based service)

### 🔐 `gplogin` - Automated VPN Login

Automates GlobalProtect login with Duo 2FA support (Yubikey preferred, push fallback).

**Usage:**

```bash
gplogin               # Connect to VPN with auto 2FA
gplogin --help        # Show help
```

**Features:**

- Automatic Yubikey detection (preferred method)
- Fallback to Duo Push notifications (*currently under testing*)
- Smart service management (doesn't restart running services)
- Waits for authentication completion
- Fills a configured portal URL only when the UI exposes a clearly labeled portal field; otherwise reports that manual configuration may be needed
- Smart popup detection and dismissal
- Configurable username (set during installation)

**Requirements:**

- GlobalProtect app installed and configured
- Duo 2FA configured (for automated login - *Duo Push fallback currently under testing*)
- macOS keychain access (credentials configured during installation)

### 🔌 `gpdisconnect` - Clean VPN Disconnect

Disconnects from GlobalProtect VPN without killing the menu bar application.

**Usage:**

```bash
gpdisconnect          # Disconnect from VPN
gpdisconnect --help   # Show help
```

### 🔑 `gpupdatepw` - Update Credentials

Updates the username and/or password stored in the macOS Keychain. Useful when credentials change.

**Features:**

- Update username only, password only, or both
- Interactive prompts for new credentials
- Validates keychain operations
- Saves username changes to the same configuration `gplogin` reads; set the password separately for a newly selected username

**Usage:**

```bash
gpupdatepw            # Update both username and password
gpupdatepw -u         # Update only username
gpupdatepw -p         # Update only password
gpupdatepw --help     # Show help
```

## Configuration

The scripts use macOS keychain for secure credential and configuration storage:

### Keychain Entries

- **`GlobalProtect`** - Stores your VPN password securely
- **`GlobalProtect-Config`** - Stores configuration as JSON (username, portal URL)

### Configuration Options

During installation, you can configure:

- **Username**: Defaults to current macOS user, but can be customized for different VPN usernames
- **Portal URL**: Optional domain (e.g., `vpn.company.com`); `gplogin` only fills it when GlobalProtect exposes a clearly labeled portal field
- **Password**: Securely stored in keychain, prompted during installation

### Manual Configuration

If you need to manually add credentials:

```bash
# Add password to keychain; security prompts for it without putting it in shell history/process arguments
security add-generic-password -a "your-username" -s "GlobalProtect" -w

# Configuration is keyed by your macOS account, while its username is the VPN account
security add-generic-password -U -a "$(whoami)" -s "GlobalProtect-Config" -w '{"username":"your-username","portal_url":"vpn.company.com"}'
```

## Compatibility

- **macOS Version:** 10.15+ (tested on recent versions)
- **Architecture:** Intel and Apple Silicon Macs
- **Homebrew:** Both `/usr/local` and `/opt/homebrew` installations
- **GlobalProtect:** Recent versions with launchctl service management

## Security Considerations

- Passwords are stored in macOS Keychain and entered through its prompt rather than passed as command-line arguments
- Configuration stored as JSON in separate keychain entry
- No credentials stored in scripts or log files
- Minimal privilege requirements
- Service management uses standard macOS tools
- Portal URL and username are stored separately from password for better security isolation

## License

These scripts are provided as-is for automation purposes. Ensure compliance with your organization's IT policies before use.
