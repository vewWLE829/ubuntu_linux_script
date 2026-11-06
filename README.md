# ubuntu_linux_script

一个存放ubuntu linux系统脚本的项目

## 脚本列表

#### 安装 fish shell 和现代命令行工具

```
curl  -fsSL https://raw.githubusercontent.com/vewWLE829/ubuntu_linux_script/refs/heads/master/install_modern_cli.sh  | bash
```

#### 释放 53 端口

```
curl -fsSL https://raw.githubusercontent.com/vewWLE829/ubuntu_linux_script/refs/heads/master/releast_53_port.sh  | bash
```

#### 配置 Ubuntu SSH 安全

脚本会检查当前用户的 SSH 公钥，并交互式配置 SSH 端口、密码登录和密钥登录。只有启用密钥登录时才允许 root 使用密钥登录；禁用密钥登录时会禁止 root 登录。运行前请先将公钥添加到当前用户的 `~/.ssh/authorized_keys`。

```bash
curl -fsSL https://raw.githubusercontent.com/vewWLE829/ubuntu_linux_script/refs/heads/master/ubuntu-ssh-security.sh -o /tmp/ubuntu-ssh-security.sh && sudo bash /tmp/ubuntu-ssh-security.sh
```

#### 解决 Ubuntu 中文乱码

```
curl  -fsSL https://raw.githubusercontent.com/vewWLE829/ubuntu_linux_script/refs/heads/master/setup_chinese_locale.sh  | bash
```

#### 安装 MesloLGS 字体

```
curl  -fsSL https://raw.githubusercontent.com/vewWLE829/ubuntu_linux_script/refs/heads/master/install_Nerd_Font.sh  | bash
```
