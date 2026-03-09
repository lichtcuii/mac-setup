#!/usr/bin/env bash

set -Eeuo pipefail

readonly OS="$(uname -s)"
readonly CONFIG_DIR="${HOME}/.config"
readonly ZSHRC="${HOME}/.zshrc"
readonly ALACRITTY_THEME_DIR="${CONFIG_DIR}/alacritty/themes"
readonly ALACRITTY_THEME_FILE="${ALACRITTY_THEME_DIR}/catppuccin-mocha.toml"
readonly ALACRITTY_THEME_URL="https://raw.githubusercontent.com/catppuccin/alacritty/main/catppuccin-mocha.toml"
readonly LAZYVIM_REPO="https://github.com/LazyVim/starter"

log() {
    printf '[INFO] %s\n' "$1"
}

warn() {
    printf '[WARN] %s\n' "$1"
}

error() {
    printf '[ERROR] %s\n' "$1" >&2
}

on_error() {
    error "Setup failed at line $1."
}

trap 'on_error $LINENO' ERR

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

append_line_once() {
    local line="$1"
    local file="$2"

    touch "$file"
    grep -qxF "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

remove_line_if_present() {
    local line="$1"
    local file="$2"
    local temp_file

    touch "$file"
    temp_file="$(mktemp)"
    awk -v target="$line" '$0 != target { print }' "$file" > "$temp_file"
    mv "$temp_file" "$file"
}

upsert_alias_line() {
    local alias_name="$1"
    local alias_value="$2"
    local file="$3"
    local temp_file

    touch "$file"
    temp_file="$(mktemp)"
    awk -v name="$alias_name" 'index($0, "alias " name "=") != 1 { print }' "$file" > "$temp_file"
    mv "$temp_file" "$file"
    printf 'alias %s="%s"\n' "$alias_name" "$alias_value" >> "$file"
}

detect_platform() {
    case "$OS" in
        Darwin)
            printf 'macos\n'
            ;;
        Linux)
            printf 'linux\n'
            ;;
        *)
            error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

install_homebrew_packages() {
    local formulas=(
        alacritty
        zellij
        starship
        neovim
        zoxide
        eza
        ripgrep
        bat
        fzf
        git
        curl
    )
    local formula

    for formula in "${formulas[@]}"; do
        if brew list "$formula" >/dev/null 2>&1; then
            log "Homebrew formula already installed: $formula"
        else
            log "Installing Homebrew formula: $formula"
            brew install "$formula"
        fi
    done

    if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
        log "Homebrew cask already installed: font-jetbrains-mono-nerd-font"
    else
        log "Installing Homebrew cask: font-jetbrains-mono-nerd-font"
        brew install --cask font-jetbrains-mono-nerd-font
    fi
}

install_macos() {
    log "Using Homebrew to install required packages."

    if ! command_exists brew; then
        error "Homebrew is not installed. Install it first, then rerun this script."
        exit 1
    fi

    brew update
    install_homebrew_packages
}

install_linux_base_packages() {
    local packages=(
        alacritty
        zellij
        neovim
        ripgrep
        bat
        fzf
        git
        curl
        zsh
    )

    log "Updating apt package index."
    sudo apt update

    log "Installing base packages from apt."
    sudo apt install -y "${packages[@]}"
}

install_linux_extras() {
    if ! command_exists starship; then
        log "Installing Starship."
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y
    else
        log "Starship already installed."
    fi

    if ! command_exists zoxide; then
        log "Installing zoxide."
        curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    else
        log "zoxide already installed."
    fi

    if ! command_exists eza; then
        log "Installing eza from apt when available."
        sudo apt install -y eza || warn "Unable to install eza via apt. Install it manually if needed."
    else
        log "eza already installed."
    fi
}

install_linux() {
    if ! command_exists apt; then
        error "This Linux path only supports apt-based distributions."
        exit 1
    fi

    install_linux_base_packages
    install_linux_extras
}

install_catppuccin_alacritty() {
    log "Installing Catppuccin Mocha theme for Alacritty."
    mkdir -p "$ALACRITTY_THEME_DIR"
    curl -fsSL "$ALACRITTY_THEME_URL" -o "$ALACRITTY_THEME_FILE"
}

write_alacritty_config() {
    log "Writing Alacritty configuration."
    mkdir -p "${CONFIG_DIR}/alacritty"

    cat > "${CONFIG_DIR}/alacritty/alacritty.toml" <<'EOF'
[general]
import = [
 "~/.config/alacritty/themes/catppuccin-mocha.toml"
]

[window]
opacity = 0.95
padding = { x = 8, y = 8 }

[font]
size = 14

[font.normal]
family = "JetBrainsMono Nerd Font"

[scrolling]
history = 10000

[cursor]
style = "Beam"

[selection]
save_to_clipboard = true

[env]
TERM = "xterm-256color"
EOF
}

write_zellij_config() {
    log "Writing Zellij configuration."
    mkdir -p "${CONFIG_DIR}/zellij"

    cat > "${CONFIG_DIR}/zellij/config.kdl" <<'EOF'
pane_frames false
scroll_buffer_size 10000
default_layout "compact"
EOF
}

write_starship_config() {
    log "Writing Starship configuration."

    cat > "${CONFIG_DIR}/starship.toml" <<'EOF'
add_newline = true

[character]
success_symbol = "[➜](green)"
error_symbol = "[➜](red)"

[directory]
style = "blue"

[git_branch]
symbol = " "

[git_status]
style = "yellow"
EOF
}

setup_git_plugin_aliases() {
    log "Configuring git aliases from oh-my-zsh git.plugin.zsh."

    upsert_alias_line 'g' 'git' "$ZSHRC"
    upsert_alias_line 'ga' 'git add' "$ZSHRC"
    upsert_alias_line 'gaa' 'git add --all' "$ZSHRC"
    upsert_alias_line 'gb' 'git branch' "$ZSHRC"
    upsert_alias_line 'gc' 'git commit --verbose' "$ZSHRC"
    upsert_alias_line 'gca' 'git commit --verbose --all' "$ZSHRC"
    upsert_alias_line 'gcam' 'git commit --all --message' "$ZSHRC"
    upsert_alias_line 'gco' 'git checkout' "$ZSHRC"
    upsert_alias_line 'gcb' 'git checkout -b' "$ZSHRC"
    upsert_alias_line 'gd' 'git diff' "$ZSHRC"
    upsert_alias_line 'gl' 'git pull' "$ZSHRC"
    upsert_alias_line 'gp' 'git push' "$ZSHRC"
    upsert_alias_line 'gst' 'git status' "$ZSHRC"

    remove_line_if_present 'alias gpl="git pull"' "$ZSHRC"
}

setup_zsh() {
    log "Updating ~/.zshrc."

    setup_git_plugin_aliases
    append_line_once 'eval "$(starship init zsh)"' "$ZSHRC"
    append_line_once 'eval "$(zoxide init zsh)"' "$ZSHRC"
    append_line_once 'alias ls="eza --icons"' "$ZSHRC"
    append_line_once 'alias ll="eza -lah --icons"' "$ZSHRC"
    append_line_once 'alias cat="bat"' "$ZSHRC"
    append_line_once 'alias tree="eza --tree"' "$ZSHRC"
    append_line_once 'if [[ -z "$ZELLIJ" ]]; then zellij; fi' "$ZSHRC"
}

install_lazyvim() {
    if [[ -d "${CONFIG_DIR}/nvim" ]]; then
        log "Existing Neovim configuration detected at ${CONFIG_DIR}/nvim. Skipping LazyVim install."
        return
    fi

    log "Installing LazyVim starter configuration."
    git clone "$LAZYVIM_REPO" "${CONFIG_DIR}/nvim"
    rm -rf "${CONFIG_DIR}/nvim/.git"
}

print_summary() {
    cat <<'EOF'

==================================
Setup completed successfully.
==================================

Next steps:
1. Reload your shell configuration:
   source ~/.zshrc
2. Open Alacritty to start using the environment.
3. Launch nvim once to let LazyVim install plugins.

Useful commands:
  gst       # git status
  gco main  # git checkout main
  gp        # git push
  z <dir>   # jump to frequently used directories
  ll        # detailed directory listing
  rg text   # fast text search

EOF
}

main() {
    local platform

    log "Starting terminal environment setup."
    mkdir -p "$CONFIG_DIR"
    platform="$(detect_platform)"

    case "$platform" in
        macos)
            install_macos
            ;;
        linux)
            install_linux
            ;;
    esac

    install_catppuccin_alacritty
    write_alacritty_config
    write_zellij_config
    write_starship_config
    setup_zsh
    install_lazyvim
    print_summary
}

main "$@"
