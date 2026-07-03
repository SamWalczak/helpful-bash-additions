### Quick Install

```bash
# Clone the repository
git clone https://github.com/SamWalczak/helpful-bash-additions.git
cd helpful-bash-additions

# Run the installer (detects macOS/Linux automatically)
chmod +x setup.sh
./setup.sh

# Reload your shell
source ~/.bashrc  # Linux
source ~/.zshrc   # macOS
```

### Manual Installation

1. Copy `bash-custom.txt` contents to your shell config:
   ```bash
   cat bash-custom.txt >> ~/.bashrc  # Linux
   cat bash-custom.txt >> ~/.zshrc   # macOS
   ```

2. Reload your shell:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

### Uninstall

```bash
# From the repository directory
./setup.sh -u

# Or with full flag
./setup.sh --uninstall

# Reload your shell
source ~/.bashrc  # Linux
source ~/.zshrc   # macOS
```

- `bhelp` - Show all custom commands
