#!/bin/bash

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_FILE="$REPO_DIR/bash-custom.txt"

BEGIN_MARK='# >>> helpful-bash-additions >>>'
END_MARK='# <<< helpful-bash-additions <<<'

detect_shell() {
    case "$(basename "${SHELL:-}")" in
        zsh)
            SHELL_NAME="zsh"
            SHELL_RC="$HOME/.zshrc"
            ;;
        bash)
            SHELL_NAME="bash"
            SHELL_RC="$HOME/.bashrc"
            ;;
        *)
            echo "Unsupported login shell: ${SHELL:-not set}"
            echo "Only bash and zsh are supported"
            exit 1
            ;;
    esac
    echo "Detected login shell: $SHELL_NAME"
    echo "Shell config: $SHELL_RC"
    echo ""
}

installed_kind() {
    if grep -qxF "$BEGIN_MARK" "$SHELL_RC" 2>/dev/null; then
        echo "block"
    elif grep -qE '^# CUSTOM BASH(/ZSH)? ADDITIONS$' "$SHELL_RC" 2>/dev/null; then
        echo "legacy"
    else
        echo "none"
    fi
}

backup_rc() {
    if [ ! -s "$SHELL_RC" ]; then
        BACKUP_FILE=""
        echo "No existing config to backup (file is new or empty)"
        return
    fi
    local base n
    base="${SHELL_RC}.backup-$(date +%Y%m%d-%H%M%S)"
    BACKUP_FILE="$base"
    n=1
    while [ -e "$BACKUP_FILE" ]; do
        BACKUP_FILE="${base}-${n}"
        n=$((n + 1))
    done
    if ! cp "$SHELL_RC" "$BACKUP_FILE"; then
        echo "Error: could not write backup $BACKUP_FILE"
        exit 1
    fi
    echo "Backup saved at: $BACKUP_FILE"
}

print_block() {
    local escaped
    escaped=$(printf '%s' "$CUSTOM_FILE" | sed "s/'/'\\\\''/g")
    echo "$BEGIN_MARK"
    echo "# Added by setup.sh. To remove: $REPO_DIR/setup.sh -u"
    echo "USE_EMOJI=$USE_EMOJI"
    if [ -n "$GS_ALIAS" ]; then
        echo "GS_ALIAS=$GS_ALIAS"
    fi
    echo "source '$escaped'"
    echo "$END_MARK"
}

rewrite_rc() {
    local mode="$1" kind tmp status
    kind="$(installed_kind)"
    tmp="$(mktemp "${TMPDIR:-/tmp}/bash-additions.XXXXXX")" || exit 1

    if [ "$mode" = "replace" ]; then
        print_block > "$tmp.block"
    else
        : > "$tmp.block"
    fi

    awk -v kind="$kind" -v begin="$BEGIN_MARK" -v end="$END_MARK" -v blockfile="$tmp.block" '
        { line[NR] = $0 }
        END {
            first = 0; last = 0
            if (kind == "block") {
                for (i = 1; i <= NR; i++) {
                    if (!first && line[i] == begin) first = i
                    if (first && !last && line[i] == end) last = i
                }
            } else {
                # Legacy copy: banner to closing fi
                for (i = 1; i <= NR && !first; i++) {
                    if (line[i] ~ /^# CUSTOM BASH(\/ZSH)? ADDITIONS$/) {
                        first = i
                        if (i > 1 && line[i - 1] ~ /^# =+$/) first = i - 1
                    }
                }
                for (i = first + 1; first && i < NR && !last; i++) {
                    if (line[i] ~ /Reset color [+] prompt/ && line[i + 1] == "fi") last = i + 1
                }
            }
            if (!first || !last) exit 3
            for (i = 1; i < first; i++) print line[i]
            while ((getline text < blockfile) > 0) print text
            for (i = last + 1; i <= NR; i++) print line[i]
        }
    ' "$SHELL_RC" > "$tmp"
    status=$?

    if [ "$status" -eq 3 ]; then
        rm -f "$tmp" "$tmp.block"
        echo "Error: found the start of an install in $SHELL_RC but not its end"
        echo "Nothing was changed. Remove the old lines by hand, then run setup again."
        exit 1
    elif [ "$status" -ne 0 ]; then
        rm -f "$tmp" "$tmp.block"
        echo "Error: could not rewrite $SHELL_RC. Nothing was changed."
        exit 1
    fi

    cat "$tmp" > "$SHELL_RC"
    rm -f "$tmp" "$tmp.block"
}

append_block() {
    # Make sure the file ends with a newline
    if [ -s "$SHELL_RC" ] && [ -n "$(tail -c 1 "$SHELL_RC")" ]; then
        echo "" >> "$SHELL_RC"
    fi
    print_block >> "$SHELL_RC"
}

ask_emoji_preference() {
    echo ""
    echo "Enable emoji in prompt?"
    echo "  y) Yes - Use emoji (default)"
    echo "  n) No  - Use [>] [<] instead (better for some terminals)"
    read -r -p "Choice [Y/n]: " emoji_choice || emoji_choice=""

    if [[ "$emoji_choice" =~ ^[Nn]$ ]]; then
        USE_EMOJI=false
    else
        USE_EMOJI=true
    fi
}

print_reload_hint() {
    echo "Changes applied. To see them in this terminal:"
    echo "  source $SHELL_RC"
    if [ "${1:-}" = "installed" ]; then
        echo "  or: bsource"
    fi
    echo ""
    echo "(or open a new terminal tab - changes are permanent)"
    echo ""
}

uninstall() {
    echo "Uninstalling custom bash additions"
    echo "=================================="
    echo ""

    detect_shell

    if [ "$(installed_kind)" = "none" ]; then
        echo "Custom bash additions not found in $SHELL_RC"
        echo "Nothing to uninstall"
        exit 0
    fi

    echo "Warning: this will remove the custom bash additions from $SHELL_RC"
    read -r -p "Are you sure? [y/N]: " confirm || confirm=""

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled"
        exit 0
    fi

    echo "Creating backup..."
    backup_rc
    echo ""

    echo "Removing custom bash additions..."
    rewrite_rc remove

    echo ""
    echo "Uninstall complete"
    echo ""
    print_reload_hint
    if [ -n "$BACKUP_FILE" ]; then
        echo "Backup saved at: $BACKUP_FILE"
        echo ""
    fi
}

install() {
    echo "Installing custom bash additions"
    echo "================================"
    echo ""

    detect_shell

    if [ ! -f "$CUSTOM_FILE" ]; then
        echo "Error: bash-custom.txt not found next to setup.sh"
        echo "Expected it at: $CUSTOM_FILE"
        exit 1
    fi

    # Create shell config file if it does not exist
    if [ ! -f "$SHELL_RC" ]; then
        echo "Shell config file not found. Creating $SHELL_RC..."
        if ! touch "$SHELL_RC"; then
            echo "Error: could not create $SHELL_RC"
            echo "Try running: touch $SHELL_RC"
            exit 1
        fi
        echo "Created $SHELL_RC"
        echo ""
    fi

    local kind
    kind="$(installed_kind)"
    GS_ALIAS=""
    if [ "$kind" = "block" ]; then
        case "$(sed -n "/^$BEGIN_MARK\$/,/^$END_MARK\$/ s/^GS_ALIAS=//p" "$SHELL_RC")" in
            gs)  GS_ALIAS=gs ;;
            gst) GS_ALIAS=gst ;;
        esac
    fi

    if [ "$kind" != "none" ]; then
        echo "Custom bash additions already found in $SHELL_RC"
        if [ "$kind" = "legacy" ]; then
            echo "(old style: a pasted copy. Update replaces it with a source line.)"
        fi
        echo "Would you like to:"
        echo "  1) Skip installation (keep existing)"
        echo "  2) Update (replace existing with new version)"
        echo "  3) Cancel"
        read -r -p "Enter choice [1/2/3]: " choice || choice=""

        case $choice in
            1)
                echo "Keeping existing installation"
                exit 0
                ;;
            2)
                echo "Updating existing installation..."
                ask_emoji_preference
                ;;
            3)
                echo "Installation cancelled"
                exit 0
                ;;
            *)
                echo "Invalid choice, exiting"
                exit 1
                ;;
        esac
    else
        ask_emoji_preference
    fi

    echo ""
    echo "Creating backup..."
    backup_rc
    echo ""

    echo "Installing custom bash additions..."
    if [ "$kind" = "none" ]; then
        append_block
    else
        rewrite_rc replace
    fi

    echo ""
    echo "Installation complete"
    echo ""
    if [ "$kind" = "none" ]; then
        print_reload_hint
    else
        print_reload_hint installed
    fi
    echo "Try it out:"
    echo "  - bhelp         (show all commands)"
    printf "  - %-14s(git status)\n" "${GS_ALIAS:-gs}"
    echo "  - toggle_emoji  (toggle emoji on/off)"
    echo ""
}

if [ "${1:-}" == "-u" ] || [ "${1:-}" == "--uninstall" ]; then
    uninstall
else
    install
fi
