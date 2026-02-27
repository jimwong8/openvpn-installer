# OpenVPN 一键安装脚本

兼容iKuai路由器及低版本OpenVPN客户端的自动化安装脚本。

## 功能特性

- ✅ 自动检测系统类型(Ubuntu/Debian/CentOS)
- ✅ 交互式配置界面
- ✅ **服务器IP自定义** - 自动检测或手动输入公网IP
- ✅ **端口自定义** - 可指定任意监听端口(默认1194)
- ✅ **客户端IP池自定义** - 可指定客户端IP分配范围
- ✅ VPN内网段自定义
- ✅ TCP/UDP协议选择
- ✅ BF-CBC加密算法(兼容旧版客户端)
- ✅ 无压缩模式(解决iKuai兼容性问题)
- ✅ PAM认证(使用系统账户登录)
- ✅ 自动配置防火墙和IP转发
- ✅ 一键生成客户端配置文件

## 系统要求

- Ubuntu 18.04+ / Debian 9+ / CentOS 7+
- Root权限
- 公网IP地址

## 快速安装

```bash
# 下载脚本
wget https://raw.githubusercontent.com/jimwong8/openvpn-installer/main/install_openvpn.sh

# 添加执行权限
chmod +x install_openvpn.sh

# 运行脚本
./install_openvpn.sh
```

## 配置选项

运行脚本后,您需要配置以下参数:

1. **服务器公网IP** - 自动检测或手动输入
2. **监听端口** - 默认1194,可自定义(如21)
3. **VPN内网IP段** - 默认10.8.0.0/255.255.255.0
4. **客户端IP分配**:
   - 留空使用自动分配
   - 或指定起始IP和结束IP(如10.8.0.100到10.8.0.200)
5. **协议类型** - TCP(推荐)或UDP

## 配置示例

### 标准配置
```
服务器IP: 45.94.43.54
监听端口: 1194
协议: TCP
VPN网段: 10.8.0.0/255.255.255.0
客户端IP: 自动分配
```

### 自定义IP池配置
```
服务器IP: 43.254.167.62
监听端口: 21
协议: TCP
VPN网段: 10.8.0.0/255.255.255.0
客户端IP池: 10.8.0.100 - 10.8.0.200
```

## 客户端连接

安装完成后,客户端配置文件位于: `/root/client.ovpn`

### 认证信息
- 用户名: `root`(或其他系统用户)
- 密码: 对应的系统密码

### 连接步骤
1. 下载 `/root/client.ovpn` 到客户端设备
2. 使用OpenVPN客户端导入配置文件
3. 输入系统用户名和密码连接

## iKuai路由器配置

iKuai路由器内置OpenVPN客户端(版本2.4.7),本脚本完全兼容:

1. 登录iKuai路由器管理界面
2. 进入 VPN → OpenVPN客户端
3. 上传客户端配置文件
4. 输入认证信息
5. 启用连接

### 兼容性说明
- ✅ 使用BF-CBC加密(旧版兼容)
- ✅ 禁用压缩(避免comp-lzo冲突)
- ✅ subnet拓扑(修复TUN/TAP错误)
- ✅ 简化配置(移除不兼容选项)

## 服务管理

```bash
# 查看服务状态
systemctl status openvpn@server

# 重启服务
systemctl restart openvpn@server

# 停止服务
systemctl stop openvpn@server

# 查看实时日志
journalctl -u openvpn@server -f

# 查看已连接客户端
cat /etc/openvpn/openvpn-status.log
```

## 防火墙配置

脚本会自动配置iptables NAT规则,如需手动调整:

```bash
# 查看NAT规则
iptables -t nat -L -n -v

# 允许OpenVPN端口(示例:21端口TCP)
iptables -A INPUT -p tcp --dport 21 -j ACCEPT

# 保存规则
iptables-save > /etc/iptables.rules
```

## 常见问题

### 1. 连接超时
- 检查服务器防火墙是否开放对应端口
- 验证服务器IP是否正确
- 确认OpenVPN服务是否运行

### 2. 认证失败
- 确认使用的是系统账户密码
- 检查PAM插件是否正确安装
- 查看服务日志排查错误

### 3. iKuai连接TUN/TAP错误
- 本脚本已解决此问题
- 使用topology subnet模式
- 禁用所有压缩选项

### 4. 无法访问外网
- 检查IP转发是否启用: `cat /proc/sys/net/ipv4/ip_forward`
- 验证NAT规则是否生效: `iptables -t nat -L`

## 技术规格

- **加密算法**: BF-CBC(Blowfish-CBC)
- **认证算法**: SHA1
- **拓扑模式**: subnet
- **认证方式**: PAM(系统账户)
- **压缩**: 禁用
- **证书**: CA证书验证
- **协议**: TCP/UDP可选

## 安全建议

1. 使用强密码保护系统账户
2. 定期更新系统和OpenVPN
3. 限制VPN访问IP范围
4. 启用日志审计
5. 考虑使用证书+密码双重认证

## 卸载

```bash
# 停止并禁用服务
systemctl stop openvpn@server
systemctl disable openvpn@server

# 删除配置文件
rm -rf /etc/openvpn/*

# 卸载软件包(Debian/Ubuntu)
apt-get remove --purge openvpn easy-rsa

# 卸载软件包(CentOS)
yum remove openvpn easy-rsa

# 清理防火墙规则
iptables -t nat -F
iptables -F
```

## 许可证

MIT License

## 作者

jimwong8

## 贡献

欢迎提交Issue和Pull Request!