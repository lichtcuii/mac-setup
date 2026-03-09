#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Terminal Environment Bootstrap Script
#
# 作用：
#   一键初始化现代终端开发环境，适用于 macOS 和基于 apt 的 Linux 发行版。
#
# 安装与配置内容：
#   - Alacritty：GPU 加速终端
#   - Zellij：终端多路复用器
#   - Starship：跨 shell 提示符
#   - Catppuccin：Alacritty 主题
#   - zoxide：智能目录跳转
#   - eza：增强版 ls
#   - ripgrep：高速文本搜索
#   - bat：带高亮的 cat
#   - fzf：模糊搜索工具
#   - Neovim + LazyVim：现代编辑器环境
#   - Git aliases：常用 Git 简写命令
#
# 脚本行为：
#   1. 根据操作系统安装所需软件
#   2. 写入 Alacritty / Zellij / Starship 配置
#   3. 向 ~/.zshrc 追加常用初始化和 alias
#   4. 安装 LazyVim（若本地尚未存在 Neovim 配置）
#   5. 配置常用 Git aliases
#
# 注意事项：
#   - 本脚本会修改 ~/.zshrc
#   - 本脚本会写入 ~/.config 下的相关配置文件
#   - 若 ~/.config/nvim 已存在，则不会覆盖现有 Neovim 配置
#   - Linux 版本默认仅支持 apt 包管理器
#
# 使用方式：
#   chmod +x setup-terminal.sh
#   ./setup-terminal.sh
# -----------------------------------------------------------------------------

set -e

echo "==== Terminal Environment Setup ===="

OS="$(uname)"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

install_macos() {
    echo "[macOS] Using Homebrew to install required packages..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "[ERROR] Homebrew is not installed."
        echo "Please install Homebrew first, then rerun this script."
        exit 1
    fi

    echo "[macOS] Updating Homebrew..."
    brew update

    echo "[macOS] Installing terminal tools..."
    brew install \
        alacritty \
        zellij \
        starship \
        neovim \
        zoxide \
        eza \
        ripgrep \
        bat \
        fzf \
        git \
        curl

    echo "[macOS] Installing JetBrains Mono Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font

    echo "[macOS] Package installation completed."
}

install_linux() {
    echo "[Linux] Using apt to install required packages..."

    echo "[Linux] Updating package index..."
    sudo apt update

    echo "[Linux] Installing base packages..."
    sudo apt install -y \
        alacritty \
        zellij \
        neovim \
        ripgrep \
        bat \
        fzf \
        git \
        curl \
        zsh

    if ! command -v starship >/dev/null 2>&1; then
        echo "[Linux] Starship not found. Installing..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        echo "[Linux] Starship already installed. Skipping."
    fi

    if ! command -v zoxide >/dev/null 2>&1; then
        echo "[Linux] zoxide not found. Installing..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    else
        echo "[Linux] zoxide already installed. Skipping."
    fi

    if ! command -v eza >/dev/null 2>&1; then
        echo "[Linux] eza not found. Attempting installation via apt..."
        sudo apt install -y eza || true
    else
        echo "[Linux] eza already installed. Skipping."
    fi

    echo "[Linux] Package installation step completed."
}

install_catppuccin_alacritty() {
    echo "[Theme] Installing Catppuccin Mocha theme for Alacritty..."

    mkdir -p "$CONFIG_DIR/alacritty/themes"

    rm -rf /tmp/catppuccin
    git clone --depth=1 https://github.com/catppuccin/alacritty.git /tmp/catppuccin

    cp /tmp/catppuccin/catppuccin-mocha.toml \
       "$CONFIG_DIR/alacritty/themes/"

    rm -rf /tmp/catppuccin

    echo "[Theme] Catppuccin theme installed."
}

write_alacritty_config() {
    echo "[Config] Writing Alacritty configuration..."
    mkdir -p "$CONFIG_DIR/alacritty"

cat > "$CONFIG_DIR/alacritty/alacritty.toml" <<EOF
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

    echo "[Config] Alacritty configuration written to $CONFIG_DIR/alacritty/alacritty.toml"
}

write_zellij_config() {
    echo "[Config] Writing Zellij configuration..."
    mkdir -p "$CONFIG_DIR/zellij"

cat > "$CONFIG_DIR/zellij/config.kdl" <<EOF
pane_frames false
scroll_buffer_size 10000
default_layout "compact"
EOF

    echo "[Config] Zellij configuration written to $CONFIG_DIR/zellij/config.kdl"
}

write_starship_config() {
    echo "[Config] Writing Starship configuration..."

cat > "$CONFIG_DIR/starship.toml" <<EOF
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

    echo "[Config] Starship configuration written to $CONFIG_DIR/starship.toml"
}

setup_git_aliases() {
    echo "[Git] Configuring global Git aliases..."

    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.cb "checkout -b"
    git config --global alias.br branch
    git config --global alias.cm commit
    git config --global alias.ci commit
    git config --global alias.amend "commit --amend"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.lg "log --oneline --graph --decorate --all"
    git config --global alias.df diff
    git config --global alias.pl pull
    git config --global alias.ps push

    echo "[Git] Git aliases configured."
}

setup_zsh() {
    echo "[Shell] Updating ~/.zshrc ..."
    ZSHRC="$HOME/.zshrc"

    touch "$ZSHRC"

    grep -qxF 'eval "$(starship init zsh)"' "$ZSHRC" || \
    echo 'eval "$(starship init zsh)"' >> "$ZSHRC"

    grep -qxF 'eval "$(zoxide init zsh)"' "$ZSHRC" || \
    echo 'eval "$(zoxide init zsh)"' >> "$ZSHRC"

    grep -qxF 'alias ls="eza --icons"' "$ZSHRC" || \
    echo 'alias ls="eza --icons"' >> "$ZSHRC"

    grep -qxF 'alias ll="eza -lah --icons"' "$ZSHRC" || \
    echo 'alias ll="eza -lah --icons"' >> "$ZSHRC"

    grep -qxF 'alias cat="bat"' "$ZSHRC" || \
    echo 'alias cat="bat"' >> "$ZSHRC"

    grep -qxF 'alias tree="eza --tree"' "$ZSHRC" || \
    echo 'alias tree="eza --tree"' >> "$ZSHRC"

    grep -qxF 'if [[ -z "$ZELLIJ" ]]; then zellij; fi' "$ZSHRC" || \
    echo 'if [[ -z "$ZELLIJ" ]]; then zellij; fi' >> "$ZSHRC"

    echo "[Shell] ~/.zshrc update completed."
}

install_lazyvim() {
    if [ ! -d "$CONFIG_DIR/nvim" ]; then
        echo "[Neovim] Installing LazyVim starter configuration..."

        git clone https://github.com/LazyVim/starter "$CONFIG_DIR/nvim"
        rm -rf "$CONFIG_DIR/nvim/.git"

        echo "[Neovim] LazyVim installed."
    else
        echo "[Neovim] Existing Neovim configuration detected at $CONFIG_DIR/nvim"
        echo "[Neovim] Skipping LazyVim installation to avoid overwriting your setup."
    fi
}

main() {
    echo "[Init] Detecting operating system..."

    if [[ "$OS" == "Darwin" ]]; then
        echo "[Init] Detected macOS."
        install_macos
    else
        echo "[Init] Detected Linux."
        install_linux
    fi

    install_catppuccin_alacritty
    write_alacritty_config
    write_zellij_config
    write_starship_config
    setup_git_aliases
    setup_zsh
    install_lazyvim

    echo ""
    echo "=================================="
    echo "Setup completed successfully."
    echo "=================================="
    echo ""
    echo "Next steps:"
    echo "1. Reload your shell configuration:"
    echo "   source ~/.zshrc"
    echo "2. Open Alacritty to start using the environment."
    echo "3. Launch nvim once to let LazyVim install plugins."
    echo ""
    echo "Useful commands:"
    echo "  git st    # git status"
    echo "  git lg    # compact git log graph"
    echo "  z <dir>   # jump to frequently used directories"
    echo "  ll        # detailed directory listing"
    echo "  rg text   # fast text search"
    echo ""
}

main
