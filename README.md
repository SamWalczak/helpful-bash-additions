### Quick Install

```bash
# Clone the repository
git clone https://github.com/SamWalczak/helpful-bash-additions.git
cd helpful-bash-additions

# Run the installer
./setup.sh
```

Follow the instructions from setup for the command to source the changes

### Manual Installation

Linux (bash):
```bash
echo "source '$PWD/bash-custom.txt'" >> ~/.bashrc
source ~/.bashrc
```

macOS (zsh):
```bash
echo "source '$PWD/bash-custom.txt'" >> ~/.zshrc
source ~/.zshrc
```

### Use

```bash
bhelp
```

`bhelp` lists every command and gives each a small explanation

### Other Features

- 🦐 and 🍤 alternating command header for better line tracking
- Timestamps, `user@host` and current path per command
- Current branch, state/staging (color-coded), commit, ahead/behind arrows, stash counts and merge conflicts when in a git repo

### Update

```bash
bupdate

# Reload your shell
bsource
```

### Uninstall

```bash
# From the repository directory
./setup.sh -u  # Or ./setup.sh --uninstall

# Or from any directory
bsetup -u
```

Refresh or open a new terminal
