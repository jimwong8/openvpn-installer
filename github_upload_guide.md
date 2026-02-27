# GitHub 上传指南

由于GitHub已不再支持使用密码进行HTTPS认证,您需要创建Personal Access Token (PAT)。

## 方法一: 使用Personal Access Token (推荐)

### 1. 创建Personal Access Token

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置Token名称: `openvpn-installer`
4. 选择权限: 勾选 `repo` (完整仓库访问权限)
5. 点击底部的 "Generate token"
6. **复制生成的token** (只显示一次!)

### 2. 创建仓库并上传

在本地终端执行:

```bash
cd /home/jimwong

# 如果仓库不存在,先在GitHub网站上创建
# 访问: https://github.com/new
# 仓库名: openvpn-installer

# 设置远程仓库(将 YOUR_TOKEN 替换为刚才复制的token)
git remote set-url origin https://YOUR_TOKEN@github.com/jimwong8/openvpn-installer.git

# 推送代码
git push -u origin main
```

## 方法二: 使用SSH密钥 (更安全)

### 1. 生成SSH密钥

```bash
ssh-keygen -t ed25519 -C "jimwong8@users.noreply.github.com"
# 按Enter使用默认路径
# 可以设置密码或直接按Enter

# 查看公钥
cat ~/.ssh/id_ed25519.pub
```

### 2. 添加SSH密钥到GitHub

1. 复制上一步显示的公钥内容
2. 访问 https://github.com/settings/keys
3. 点击 "New SSH key"
4. 标题: `OpenVPN Installer`
5. 粘贴公钥内容
6. 点击 "Add SSH key"

### 3. 使用SSH推送

```bash
cd /home/jimwong

# 修改远程仓库为SSH地址
git remote set-url origin git@github.com:jimwong8/openvpn-installer.git

# 推送代码
git push -u origin main
```

## 方法三: 使用GitHub CLI (最简单)

```bash
# 安装GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# 登录GitHub
gh auth login
# 选择: GitHub.com → HTTPS → Yes → Login with a web browser
# 按照提示在浏览器中完成授权

# 创建仓库并推送
cd /home/jimwong
gh repo create openvpn-installer --public --source=. --remote=origin --push
```

## 当前文件状态

已准备好上传的文件:
- `install_openvpn.sh` - OpenVPN一键安装脚本
- `README.md` - 详细的使用文档

## 快速命令 (使用Token)

```bash
# 1. 在 https://github.com/settings/tokens 创建token
# 2. 在 https://github.com/new 创建仓库 openvpn-installer
# 3. 执行以下命令 (替换YOUR_TOKEN)

cd /home/jimwong
git remote set-url origin https://YOUR_TOKEN@github.com/jimwong8/openvpn-installer.git
git add README.md
git commit -m "添加详细的README文档"
git push -u origin main
```

## 验证上传

上传成功后,访问: https://github.com/jimwong8/openvpn-installer

您应该能看到:
- install_openvpn.sh
- README.md
- 完整的文档说明