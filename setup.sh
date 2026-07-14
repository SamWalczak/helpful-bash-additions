#!/bin/bash

# Function to detect OS and set shell config
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
        SHELL_RC="$HOME/.zshrc"
        BACKUP_RC="$HOME/.zshrc.backup"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        SHELL_RC="$HOME/.bashrc"
        BACKUP_RC="$HOME/.bashrc.backup"
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Ask about emoji preference
ask_emoji_preference() {
    echo ""
    echo "Enable emoji in prompt?"
    echo "  y) Yes - Use emoji (default)"
    echo "  n) No  - Use [>] [<] instead (better for some terminals)"
    read -p "Choice [Y/n]: " emoji_choice
    
    if [[ "$emoji_choice" =~ ^[Nn]$ ]]; then
        USE_EMOJI=false
    else
        USE_EMOJI=true
    fi
}

# Apply emoji preference to the installed config
apply_emoji_preference() {
    if [ "$USE_EMOJI" = false ]; then
        sed -i.tmp 's/^USE_EMOJI=true/USE_EMOJI=false/' "$SHELL_RC"
        rm -f "${SHELL_RC}.tmp"
    fi
}

# Uninstall function
uninstall() {
    echo "Uninstalling Custom Bash Configuration"
    echo "======================================="
    echo ""
    
    detect_os
    
    if [ "$OS" == "mac" ]; then
        echo "Detected: macOS"
    else
        echo "Detected: Linux"
    fi
    echo "Shell config: $SHELL_RC"
    echo ""
    
    # Check if custom bash is installed
    if ! grep -q "# CUSTOM BASH" "$SHELL_RC" 2>/dev/null; then
        echo "Custom bash additions not found in $SHELL_RC"
        echo "Nothing to uninstall!"
        exit 0
    fi
    
    # Confirm uninstall
    echo "WARNING: This will remove all custom bash additions from $SHELL_RC"
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled"
        exit 0
    fi
    
    # Backup before uninstalling
    echo "Creating backup..."
    cp "$SHELL_RC" "${SHELL_RC}.backup-$(date +%s)"
    echo "Backup saved: ${SHELL_RC}.backup-$(date +%s)"
    echo ""
    
    # Remove custom bash additions
    echo "Removing custom bash additions..."
    # Remove everything from # CUSTOM BASH to end of file
    sed -i.tmp '/# CUSTOM BASH/,$d' "$SHELL_RC"
    rm -f "${SHELL_RC}.tmp"
    # Remove trailing lines that are blank or only contain # and =
    LAST_LINE=$(grep -n '[a-zA-Z0-9]' "$SHELL_RC" | tail -1 | cut -d: -f1)
    if [ -n "$LAST_LINE" ]; then
        head -n "$LAST_LINE" "$SHELL_RC" > "$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"
    else
        # No alphanumeric content found - file should be empty
        > "$SHELL_RC"
    fi
    
    echo ""
    echo "Uninstall complete!"
    echo ""
    echo "Changes applied! To see them in THIS terminal:"
    if [ "$OS" == "mac" ]; then
        echo "  source ~/.zshrc"
    else
        echo "  source ~/.bashrc"
    fi
    echo ""
    echo "(Or open a new terminal tab - changes are permanent)"
    echo ""
    echo "Backup saved at: ${SHELL_RC}.backup-$(date +%s)"
    echo ""
}

# Install function
install() {
    echo "Installing Custom Bash Configuration"
    echo "====================================="
    echo ""
    
    detect_os
    
    if [ "$OS" == "mac" ]; then
        echo "Detected: macOS"
    else
        echo "Detected: Linux"
    fi
    echo "Shell config: $SHELL_RC"
    echo ""
    
    # Create shell RC file if it doesn't exist
    if [ ! -f "$SHELL_RC" ]; then
        echo "Shell config file not found. Creating $SHELL_RC..."
        touch "$SHELL_RC"
        if [ $? -ne 0 ]; then
            echo "Error: Could not create $SHELL_RC"
            echo "Try running: touch $SHELL_RC"
            exit 1
        fi
        echo "Created $SHELL_RC"
        echo ""
    fi
    
    # Check if bash-custom.txt exists
    if [ ! -f "bash-custom.txt" ]; then
        echo "Error: bash-custom.txt not found in current directory"
        echo "Please run this script from the repository root"
        exit 1
    fi
    
    # Backup existing config
    echo "Creating backup..."
    if [ -s "$SHELL_RC" ]; then
        # File exists and is not empty
        cp "$SHELL_RC" "$BACKUP_RC"
        echo "Backup saved: $BACKUP_RC"
    else
        echo "No existing config to backup (file is new or empty)"
    fi
    echo ""
    
    # Check if already installed
    if grep -q "# CUSTOM BASH" "$SHELL_RC" 2>/dev/null; then
        echo "Custom bash additions already found in $SHELL_RC"
        echo "Would you like to:"
        echo "  1) Skip installation (keep existing)"
        echo "  2) Update (replace existing with new version)"
        echo "  3) Cancel"
        read -p "Enter choice [1/2/3]: " choice
        
        case $choice in
            1)
                echo "Keeping existing installation"
                exit 0
                ;;
            2)
                echo "Updating existing installation..."
                # Remove everything from # CUSTOM BASH to end of file
                sed -i.tmp '/# CUSTOM BASH/,$d' "$SHELL_RC"
                rm -f "${SHELL_RC}.tmp"
                # Remove trailing lines that are blank or only contain # and =
                LAST_LINE=$(grep -n '[a-zA-Z0-9]' "$SHELL_RC" | tail -1 | cut -d: -f1)
                if [ -n "$LAST_LINE" ]; then
                    head -n "$LAST_LINE" "$SHELL_RC" > "$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"
                else
                    # No alphanumeric content found - file should be empty
                    > "$SHELL_RC"
                fi
                # Ask about emoji preference for update
                ask_emoji_preference
                ;;
            3)
                echo "Installation cancelled"
                exit 0
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    else
        # Fresh install - ask about emoji preference
        ask_emoji_preference
    fi
    
    # Append bash-custom.txt to shell config
    echo "Installing custom bash additions..."
    cat bash-custom.txt >> "$SHELL_RC"
    
    # Apply emoji preference
    apply_emoji_preference
    
    echo ""
    echo "Installation complete!"
    echo ""
    echo "Changes applied! To see them in THIS terminal:"
    if [ "$OS" == "mac" ]; then
        echo "  source ~/.zshrc"
    else
        echo "  source ~/.bashrc"
    fi
    echo ""
    echo "(Or open a new terminal tab - changes are permanent)"
    echo ""
    echo "Try it out:"
    echo "  - bhelp         (Show all commands)"
    echo "  - gs            (Git status)"
    echo "  - toggle_emoji  (Toggle emoji on/off)"
    echo ""
}

# Main script logic
if [ "$1" == "-u" ] || [ "$1" == "--uninstall" ]; then
    uninstall
else
    install
fi
