#!/usr/bin/env bash
set -e

step() {
    echo ""
    echo "👉 $1"
    sleep 1.5
}

# 更新系统软件源
step "更新系统软件源"
apt update

# 安装基础工具
step "安装基础工具"
apt install -y \
    curl \
    vim \
    wget

# 安装 Fish 4
step "安装 Fish 4.0+"

FISH_NEED_INSTALL=false

if ! command -v fish &>/dev/null; then
    echo "👉 fish 未安装，开始安装"
    FISH_NEED_INSTALL=true
else
    FISH_VERSION=$(fish --version 2>&1 | grep -oP '\d+' | head -1)

    if [ "$FISH_VERSION" -lt 4 ]; then
        echo "fish 版本低于 4.0（当前版本: $(fish --version)），升级安装"
        FISH_NEED_INSTALL=true
    else
        echo "✅ fish（$(fish --version)）已安装，跳过"
    fi
fi

if [ "$FISH_NEED_INSTALL" = true ]; then
    apt install software-properties-common -y
    add-apt-repository ppa:fish-shell/release-4 -y
    apt update
    apt install fish -y

    step "设置默认 shell 为 fish"
    chsh -s "$(which fish)"
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


# 配置 fd 命令兼容性
step "配置 fd 命令兼容性"

if [ ! -f /usr/local/bin/fd ]; then
    ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# 配置 bat 命令兼容性
step "配置 bat 命令兼容性"

if [ ! -f /usr/local/bin/bat ]; then
    ln -sf "$(which batcat)" /usr/local/bin/bat
fi

# 安装 Delta 对比工具
step "安装 Delta 对比工具"
DELTA_VERSION="0.19.2"
if ! command -v delta &>/dev/null; then
    wget -q -O /tmp/delta.deb \
    https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb

    dpkg -i /tmp/delta.deb || apt -f install -y
else
    echo "✅ delta 已安装: $(delta --version)"
fi

# 安装 tldr 命令帮助工具
step "安装 tldr 命令帮助工具"
if ! command -v tldr &>/dev/null; then
    TLDR_URL="https://github.com/tealdeer-rs/tealdeer/releases/download/v1.8.1/tealdeer-linux-x86_64-musl"
    wget -O /tmp/tealdeer-linux-x86_64-musl "$TLDR_URL"
    chmod +x /tmp/tealdeer-linux-x86_64-musl
    mv /tmp/tealdeer-linux-x86_64-musl /usr/local/bin/tldr
else
    echo "✅ tldr 已安装，跳过"
fi

# 安装 Docker
step "检查 Docker 安装状态"
if ! command -v docker &>/dev/null; then
    echo "👉 Docker 未安装，开始安装"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker 安装完成"
else
    echo "✅ Docker 已安装: $(docker --version)"
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
alias aria2='aria2c -c -x 8 -s 8 -k 1M --file-allocation=none --auto-file-renaming=false'
EOF

cat > ~/.config/fish/conf.d/zoxide.fish << 'EOF'
zoxide init fish | source
EOF

echo "✅ 执行完毕"