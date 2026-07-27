#!/usr/bin/env bash
set -e

green="\033[32m"
blue="\033[36m"
yellow="\033[33m"
reset="\033[0m"

step() {
    echo ""
    echo -e "${blue}👉 $1${reset}"
    sleep 0.5
}

success() {
    echo -e "${green}✅ $1${reset}"
}

skip() {
    echo -e "${yellow}⏭️ $1${reset}"
}

info() {
    echo -e "${blue}👉 $1${reset}"
}

# 更新系统软件源
step "更新系统软件源"
apt update
success "软件源更新完成"

# 安装基础工具
step "安装基础工具"
apt install -y \
    curl \
    vim \
    wget
success "基础工具安装完成"

# 配置 Vim
step "配置 Vim"
if [ ! -f ~/.vimrc ]; then
    cat > ~/.vimrc << 'EOF'
" 显示行号
set number

" 开启语法高亮
syntax on

" 自动缩进
set autoindent

" Tab 使用 4 个空格
set tabstop=4
set shiftwidth=4
set expandtab

" 搜索高亮
set hlsearch

" 支持鼠标操作
set mouse=a
EOF
    success "Vim 配置完成"
else
    skip "~/.vimrc 已存在，跳过"
fi

# 安装 Fish 4
step "安装 Fish 4.0+"

FISH_NEED_INSTALL=false

if ! command -v fish &>/dev/null; then
    info "fish 未安装，开始安装"
    FISH_NEED_INSTALL=true
else
    FISH_VERSION=$(fish --version 2>&1 | grep -oP '\d+' | head -1)

    if [ "$FISH_VERSION" -lt 4 ]; then
        info "fish 版本低于 4.0（当前版本: $(fish --version)），升级安装"
        FISH_NEED_INSTALL=true
    else
        skip "fish 已安装: $(fish --version)"
    fi
fi

if [ "$FISH_NEED_INSTALL" = true ]; then
    apt install software-properties-common -y
    add-apt-repository ppa:fish-shell/release-4 -y
    apt update
    apt install fish -y

    step "设置默认 shell 为 fish"
    chsh -s "$(which fish)"

    success "fish 安装完成: $(fish --version)"
fi

# 安装现代命令行工具
step "安装现代命令行工具"

apt install -y \
    eza \
    bat \
    zoxide \
    ripgrep \
    fd-find \
    jq \
    aria2

success "现代命令行工具安装完成"


# 配置 fd 命令兼容性
step "配置 fd 命令兼容性"

if [ ! -f /usr/local/bin/fd ]; then
    ln -sf "$(which fdfind)" /usr/local/bin/fd
    success "fd 命令配置完成"
else
    skip "fd 已配置，跳过"
fi


# 配置 bat 命令兼容性
step "配置 bat 命令兼容性"

if [ ! -f /usr/local/bin/bat ]; then
    ln -sf "$(which batcat)" /usr/local/bin/bat
    success "bat 命令配置完成"
else
    skip "bat 已配置，跳过"
fi


# 安装 Delta 对比工具
step "安装 Delta 对比工具"

DELTA_VERSION="0.19.2"

if ! command -v delta &>/dev/null; then
    wget -q -O /tmp/delta.deb \
    https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb

    dpkg -i /tmp/delta.deb || apt -f install -y

    success "delta 安装完成"
else
    skip "delta 已安装: $(delta --version)"
fi


# 安装 tldr 命令帮助工具
step "安装 tldr 命令帮助工具"

if ! command -v tldr &>/dev/null; then
    TLDR_URL="https://github.com/tealdeer-rs/tealdeer/releases/download/v1.8.1/tealdeer-linux-x86_64-musl"

    wget -O /tmp/tealdeer-linux-x86_64-musl "$TLDR_URL"
    chmod +x /tmp/tealdeer-linux-x86_64-musl
    mv /tmp/tealdeer-linux-x86_64-musl /usr/local/bin/tldr

    success "tldr 安装完成"
else
    skip "tldr 已安装，跳过"
fi


# 安装 Docker
step "检查 Docker 安装状态"

if ! command -v docker &>/dev/null; then
    info "Docker 未安装，开始安装"

    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker

    success "Docker 安装完成"
else
    skip "Docker 已安装: $(docker --version)"
fi


# 生成 fish 配置文件
step "生成 fish 配置文件"

mkdir -p ~/.config/fish/conf.d

cat > ~/.config/fish/conf.d/aliases.fish << 'EOF'
alias cat='bat'
alias diff='delta --side-by-side'
alias ls='eza --icons'
alias ll='eza -la --icons'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
alias aria2c='aria2c -c -x 8 -s 8 -k 1M --file-allocation=none --auto-file-renaming=false'
EOF

cat > ~/.config/fish/conf.d/zoxide.fish << 'EOF'
zoxide init fish | source
EOF

success "fish 配置文件生成完成"

echo ""
success "执行完毕"