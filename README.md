### Quick Install

```bash
# Clone the repository
git clone https://github.com/SamWalczak/helpful-bash-additions.git
cd helpful-bash-additions

# Run the installer
chmod +x setup.sh
./setup.sh

# Reload your shell
source ~/.bashrc  # Linux
source ~/.zshrc   # macOS
```

### Manual Installation

1. Add a line to your shell config that loads `bash-custom.txt` from the cloned folder:
   ```bash
   echo "source '$PWD/bash-custom.txt'" >> ~/.bashrc  # Linux
   echo "source '$PWD/bash-custom.txt'" >> ~/.zshrc   # macOS
   ```

2. Reload your shell:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

### Update

```bash
git pull

# Reload your shell
source ~/.bashrc  # Linux
source ~/.zshrc   # macOS
```

### Uninstall

```bash
# From the repository directory
./setup.sh -u  # Or ./setup.sh --uninstall

# Reload your shell
source ~/.bashrc  # Linux
source ~/.zshrc   # macOS
```

`bhelp` - Show all custom commands
