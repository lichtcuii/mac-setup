# mac-setup

一个面向 macOS 和基于 `apt` 的 Linux 的终端环境初始化脚本。

它会安装并配置一套偏现代化的命令行开发环境，包括终端、Shell 提示符、常用 CLI 工具、Neovim 初始配置，以及一组来自 oh-my-zsh `git.plugin.zsh` 的 Git shell alias。

## 包含内容

- Alacritty
- Zellij
- Starship
- Catppuccin Mocha for Alacritty
- zoxide
- eza
- ripgrep
- bat
- fzf
- Neovim
- LazyVim starter
- Git shell aliases

## 适用平台

- macOS
  需要提前安装 Homebrew
- Linux
  当前仅支持基于 `apt` 的发行版

## 脚本行为

执行 [`setup-terminal.sh`](/Users/lichtcui/Documents/project/mac-setup/setup-terminal.sh) 后会：

1. 安装缺失的软件包
2. 写入 Alacritty、Zellij、Starship 配置
3. 下载 Catppuccin Alacritty 主题
4. 向 `~/.zshrc` 追加常用初始化语句和 alias
5. 注入来自 oh-my-zsh `git.plugin.zsh` 的 Git shell alias
6. 在本地不存在 `~/.config/nvim` 时安装 LazyVim starter

## 使用方法

```bash
chmod +x setup-terminal.sh
./setup-terminal.sh
```

执行完成后：

```bash
source ~/.zshrc
```

然后建议：

- 打开 Alacritty 检查字体与主题
- 首次运行 `nvim` 让 LazyVim 自动安装插件

## 默认写入的配置

### `~/.zshrc`

会按需写入以下内容；Git aliases 会按 oh-my-zsh 的定义覆盖旧值，并移除上一步里加入的非官方 `gpl`：

- `alias g="git"`
- `alias ga="git add"`
- `alias gaa="git add --all"`
- `alias gb="git branch"`
- `alias gc="git commit --verbose"`
- `alias gca="git commit --verbose --all"`
- `alias gcam="git commit --all --message"`
- `alias gco="git checkout"`
- `alias gcb="git checkout -b"`
- `alias gd="git diff"`
- `alias gl="git pull"`
- `alias gp="git push"`
- `alias gst="git status"`
- `eval "$(starship init zsh)"`
- `eval "$(zoxide init zsh)"`
- `alias ls="eza --icons"`
- `alias ll="eza -lah --icons"`
- `alias cat="bat"`
- `alias tree="eza --tree"`
- `if [[ -z "$ZELLIJ" ]]; then zellij; fi`

### Git shell aliases

这些别名写入 `~/.zshrc`，定义参考 oh-my-zsh 官方 git 插件：
来源：https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh

例如：

- `gst` -> `git status`
- `gco main` -> `git checkout main`
- `gcb feature/demo` -> `git checkout -b feature/demo`
- `gaa` -> `git add --all`
- `gcam "message"` -> `git commit --all --message "message"`
- `gp` -> `git push`

## 注意事项

- 脚本会修改 `~/.zshrc`
- 脚本会覆盖 `~/.config/alacritty/alacritty.toml`
- 脚本会覆盖 `~/.config/zellij/config.kdl`
- 脚本会覆盖 `~/.config/starship.toml`
- 如果已经存在 `~/.config/nvim`，脚本不会覆盖你的 Neovim 配置
- Linux 下部分工具可能因发行版软件源差异无法直接通过 `apt` 安装

## 改进点

当前版本相较初始脚本做了这些优化：

- 增加 `set -Eeuo pipefail`，失败时更容易定位问题
- 抽离公共函数，减少重复逻辑
- Homebrew 安装改为跳过已安装项目，提升幂等性
- Catppuccin 主题下载改为直接拉取原始文件，避免临时 clone 仓库
- `~/.zshrc` 写入抽象为统一的去重追加逻辑
- README 补充了用途、行为、风险和使用方式
