
#!/bin/bash

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_DIR="/etc/ssh/sshd_config.d"
CUSTOM_CONFIG="${SSHD_DIR}/00-custom.conf"
SSHD_BIN="/usr/sbin/sshd"

# 0. 检查运行权限及 SSH 服务
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用 sudo 运行此脚本"
    exit 1
fi

if [ ! -f "$SSHD_CONFIG" ] || [ ! -x "$SSHD_BIN" ]; then
    echo "❌ 未找到 SSH 服务配置或程序"
    echo "请先安装 openssh-server"
    exit 1
fi

# 1. 检查当前用户公钥
TARGET_USER="${SUDO_USER:-root}"
USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
AUTH_KEYS="${USER_HOME}/.ssh/authorized_keys"

if [ -s "$AUTH_KEYS" ]; then
    echo "✅ 检测到 SSH 公钥文件: $AUTH_KEYS"
else
    echo "⚠️ 未检测到 SSH 公钥文件: $AUTH_KEYS"
    exit 1
fi

# 2. 检查 SSH 配置片段机制
if ! grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config.d/\*\.conf' "$SSHD_CONFIG"; then
    echo "❌ 未找到 SSH 配置片段 Include"
    exit 1
fi

mkdir -p "$SSHD_DIR"

# 3. 备份配置
BACKUP_FILE="${CUSTOM_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"

if [ -f "$CUSTOM_CONFIG" ]; then
    cp -p "$CUSTOM_CONFIG" "$BACKUP_FILE"
    HAD_BACKUP=1
else
    HAD_BACKUP=0
fi

echo "==> SSH 配置修改"

# 4. 修改 SSH 端口
CURRENT_PORT=$("$SSHD_BIN" -T | awk '$1 == "port" {print $2; exit}')

if [ -z "$CURRENT_PORT" ]; then
    CURRENT_PORT="22"
fi

printf "请输入 SSH 端口 [当前: %s]: " "$CURRENT_PORT"
read -r SSH_PORT

if [ -z "$SSH_PORT" ]; then
    SSH_PORT="$CURRENT_PORT"
fi

case "$SSH_PORT" in
    *[!0-9]*|"")
        echo "❌ SSH 端口必须是数字"
        exit 1
        ;;
esac

if [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
    echo "❌ SSH 端口范围必须是 1-65535"
    exit 1
fi

# 5. 是否禁用密码登录
printf "是否禁用 SSH 密码登录? (y/N): "
read -r DISABLE_PASSWORD

case "$DISABLE_PASSWORD" in
    y|Y)
        PASSWORD_AUTH="no"
        echo "密码登录已禁用"
        ;;
    *)
        PASSWORD_AUTH="yes"
        echo "密码登录保持启用"
        ;;
esac

# 6. 是否开启密钥登录
printf "是否开启 SSH 密钥登录? (Y/n): "
read -r ENABLE_PUBKEY

case "$ENABLE_PUBKEY" in
    n|N)
        PUBKEY_AUTH="no"
        ROOT_LOGIN="no"
        echo "密钥登录已禁用"
        ;;
    *)
        PUBKEY_AUTH="yes"
        ROOT_LOGIN="prohibit-password"
        echo "密钥登录已开启"
        ;;
esac

# 7. 写入 SSH 配置
cat > "$CUSTOM_CONFIG" <<EOF
# Custom SSH Configuration
Port ${SSH_PORT}
PasswordAuthentication ${PASSWORD_AUTH}
PubkeyAuthentication ${PUBKEY_AUTH}
PermitRootLogin ${ROOT_LOGIN}
EOF

chmod 644 "$CUSTOM_CONFIG"

# 8. 检查 SSH 配置语法
echo "==> 检查 sshd 配置"

if "$SSHD_BIN" -t; then
    echo "✅ sshd 配置检查通过"
else
    echo "❌ sshd 配置语法错误，恢复备份"

    if [ "$HAD_BACKUP" -eq 1 ]; then
        cp -p "$BACKUP_FILE" "$CUSTOM_CONFIG"
    else
        rm -f "$CUSTOM_CONFIG"
    fi

    exit 1
fi

# 9. 重启 SSH 服务
echo "==> 重启 SSH 服务"

if ! systemctl restart ssh; then
    echo "❌ SSH 服务重启失败，恢复备份"

    if [ "$HAD_BACKUP" -eq 1 ]; then
        cp -p "$BACKUP_FILE" "$CUSTOM_CONFIG"
    else
        rm -f "$CUSTOM_CONFIG"
    fi

    systemctl restart ssh
    exit 1
fi

echo "✅ SSH 配置修改完成"
echo "SSH 端口: ${SSH_PORT}"
echo "密码登录: ${PASSWORD_AUTH}"
echo "密钥登录: ${PUBKEY_AUTH}"
echo "Root 登录: ${ROOT_LOGIN}"
echo "备份文件: ${BACKUP_FILE}"
