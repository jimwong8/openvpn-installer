#!/bin/bash

#############################################
# OpenVPN 服务器一键安装脚本
# 兼容iKuai路由器及低版本OpenVPN客户端
# 使用BF-CBC加密，无压缩，subnet拓扑
#############################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 检测系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "无法检测操作系统类型"
        exit 1
    fi
    
    log_info "检测到系统: $OS $VER"
}

# 获取服务器公网IP
get_server_ip() {
    local ip
    ip=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip)
    if [ -z "$ip" ]; then
        log_warn "无法自动获取公网IP"
        echo ""
    else
        echo "$ip"
    fi
}

# 交互式配置
interactive_config() {
    echo ""
    echo "=========================================="
    echo "   OpenVPN 服务器配置"
    echo "=========================================="
    echo ""
    
    # 服务器IP
    local detected_ip=$(get_server_ip)
    if [ -n "$detected_ip" ]; then
        read -p "服务器公网IP [$detected_ip]: " SERVER_IP
        SERVER_IP=${SERVER_IP:-$detected_ip}
    else
        read -p "服务器公网IP: " SERVER_IP
        while [ -z "$SERVER_IP" ]; do
            log_error "服务器IP不能为空"
            read -p "服务器公网IP: " SERVER_IP
        done
    fi
    
    # 监听端口
    echo ""
    read -p "OpenVPN监听端口 (标准端口: UDP=1194, TCP=443) [1194]: " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-1194}
    
    # 端口建议
    if [ "$SERVER_PORT" = "21" ] || [ "$SERVER_PORT" = "443" ]; then
        log_warn "注意: 端口 $SERVER_PORT 可能被云服务商的安全策略拦截"
        log_warn "如遇连接问题,建议使用: UDP 1194 或 TCP 8443"
    fi
    
    # VPN内网段
    read -p "VPN内网IP段 (格式: 10.8.0.0): " VPN_NETWORK
    VPN_NETWORK=${VPN_NETWORK:-10.8.0.0}
    
    read -p "VPN子网掩码 (格式: 255.255.255.0): " VPN_NETMASK
    VPN_NETMASK=${VPN_NETMASK:-255.255.255.0}
    
    # 客户端IP分配范围
    echo ""
    echo "客户端IP分配设置:"
    echo "留空使用自动分配模式，或指定IP池范围"
    read -p "客户端起始IP (例如: 10.8.0.100，留空自动分配): " CLIENT_IP_START
    read -p "客户端结束IP (例如: 10.8.0.200，留空自动分配): " CLIENT_IP_END
    
    if [ -n "$CLIENT_IP_START" ] && [ -n "$CLIENT_IP_END" ]; then
        USE_IP_POOL="yes"
        log_info "将使用IP池范围: $CLIENT_IP_START - $CLIENT_IP_END"
    else
        USE_IP_POOL="no"
        log_info "将使用自动分配模式"
    fi
    
    # 协议选择
    echo ""
    echo "=========================================="
    echo "选择传输协议:"
    echo "=========================================="
    echo "1) TCP"
    echo "   - 优点: 连接稳定,适合有防火墙限制的网络"
    echo "   - 缺点: 性能略低于UDP"
    echo "   - 推荐: 企业网络、云服务器"
    echo ""
    echo "2) UDP (推荐)"
    echo "   - 优点: 性能最佳,OpenVPN标准协议"
    echo "   - 缺点: 可能被部分防火墙拦截"
    echo "   - 推荐: 家庭网络、VPS服务器"
    echo ""
    read -p "请选择协议类型 (1=TCP, 2=UDP) [2]: " PROTO_CHOICE
    PROTO_CHOICE=${PROTO_CHOICE:-2}
    
    if [ "$PROTO_CHOICE" = "1" ]; then
        SERVER_PROTO="tcp"
        log_info "已选择: TCP协议"
    else
        SERVER_PROTO="udp"
        log_info "已选择: UDP协议 (推荐)"
    fi
    
    # 显示配置摘要
    echo ""
    echo "=========================================="
    echo "   配置摘要"
    echo "=========================================="
    echo "服务器IP: $SERVER_IP"
    echo "监听端口: $SERVER_PORT"
    echo "协议类型: $SERVER_PROTO"
    echo "VPN网段: $VPN_NETWORK $VPN_NETMASK"
    if [ "$USE_IP_POOL" = "yes" ]; then
        echo "客户端IP池: $CLIENT_IP_START - $CLIENT_IP_END"
    else
        echo "客户端IP: 自动分配"
    fi
    echo "=========================================="
    echo ""
    
    read -p "确认以上配置并继续安装? (y/n) [y]: " CONFIRM
    CONFIRM=${CONFIRM:-y}
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        log_info "安装已取消"
        exit 0
    fi
}

# 安装依赖
install_dependencies() {
    log_info "更新系统并安装依赖..."
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update -qq
        apt-get install -y openvpn easy-rsa iptables curl
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum install -y epel-release
        yum install -y openvpn easy-rsa iptables curl
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi
    
    log_info "依赖安装完成"
}

# 配置PKI和生成证书
setup_pki() {
    log_info "配置PKI并生成证书..."
    
    # 创建easy-rsa目录
    mkdir -p /etc/openvpn/easy-rsa
    cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
    cd /etc/openvpn/easy-rsa
    
    # 初始化PKI
    echo "yes" | ./easyrsa init-pki
    
    # 生成CA证书（无密码）
    echo -e "\n\n\n\n\n\n\n" | ./easyrsa build-ca nopass
    
    # 生成服务器证书
    echo "" | ./easyrsa gen-req server nopass
    echo "yes" | ./easyrsa sign-req server server
    
    # 生成DH参数
    ./easyrsa gen-dh
    
    # 生成客户端证书
    echo "" | ./easyrsa gen-req client1 nopass
    echo "yes" | ./easyrsa sign-req client client1
    
    # 复制证书到OpenVPN目录
    cp pki/ca.crt /etc/openvpn/
    cp pki/issued/server.crt /etc/openvpn/
    cp pki/private/server.key /etc/openvpn/
    cp pki/dh.pem /etc/openvpn/dh2048.pem
    
    log_info "证书生成完成"
}

# 创建服务器配置
create_server_config() {
    log_info "创建服务器配置文件..."
    
    cat > /etc/openvpn/server.conf << EOF
port $SERVER_PORT
proto $SERVER_PROTO
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-server
topology subnet
server $VPN_NETWORK $VPN_NETMASK
ifconfig-pool-persist ipp.txt
EOF

    # 如果指定了IP池范围，添加配置
    if [ "$USE_IP_POOL" = "yes" ]; then
        echo "ifconfig-pool $CLIENT_IP_START $CLIENT_IP_END" >> /etc/openvpn/server.conf
    fi
    
    cat >> /etc/openvpn/server.conf << EOF
keepalive 10 60
cipher BF-CBC
auth SHA1
persist-key
persist-tun
status openvpn-status.log
verb 3
duplicate-cn
script-security 2
username-as-common-name
plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so login
EOF

    # TCP特定配置
    if [ "$SERVER_PROTO" = "tcp" ]; then
        echo "tcp-nodelay" >> /etc/openvpn/server.conf
    fi
    
    cat >> /etc/openvpn/server.conf << 'EOF'
EOF
    
    log_info "服务器配置完成"
}

# 配置网络转发
setup_networking() {
    log_info "配置IP转发和防火墙..."
    
    # 启用IP转发
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    
    # 获取主网络接口
    local iface
    iface=$(ip route | grep default | awk '{print $5}' | head -n1)
    
    if [ -z "$iface" ]; then
        iface="eth0"
        log_warn "无法自动检测网络接口，使用默认: $iface"
    fi
    
    # 配置iptables规则
    # 允许OpenVPN端口
    if [ "$SERVER_PROTO" = "tcp" ]; then
        iptables -A INPUT -p tcp --dport $SERVER_PORT -j ACCEPT
    else
        iptables -A INPUT -p udp --dport $SERVER_PORT -j ACCEPT
    fi
    
    # 允许TUN接口转发
    iptables -A FORWARD -i tun0 -j ACCEPT
    iptables -A FORWARD -o tun0 -j ACCEPT
    
    # 配置NAT
    iptables -t nat -A POSTROUTING -s $VPN_NETWORK/24 -o $iface -j MASQUERADE
    
    # 保存iptables规则
    if command -v iptables-save > /dev/null; then
        iptables-save > /etc/iptables.rules
        
        # 创建启动时自动加载规则的服务
        cat > /etc/systemd/system/iptables-restore.service << EOF
[Unit]
Description=Restore iptables rules
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables.rules

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl enable iptables-restore.service > /dev/null 2>&1
    fi
    
    log_info "网络配置完成"
}

# 启动OpenVPN服务
start_openvpn() {
    log_info "启动OpenVPN服务..."
    
    systemctl enable openvpn@server > /dev/null 2>&1
    systemctl start openvpn@server
    
    sleep 2
    
    if systemctl is-active --quiet openvpn@server; then
        log_info "OpenVPN服务启动成功"
    else
        log_error "OpenVPN服务启动失败"
        systemctl status openvpn@server
        exit 1
    fi
}

# 生成客户端配置文件
generate_client_config() {
    log_info "生成客户端配置文件..."
    
    local client_config="/root/client.ovpn"
    
    cat > $client_config << EOF
client
dev tun
proto $SERVER_PROTO
remote $SERVER_IP $SERVER_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
cipher BF-CBC
auth SHA1
verb 3
tls-client
EOF

    # TCP特定客户端配置
    if [ "$SERVER_PROTO" = "tcp" ]; then
        echo "tcp-nodelay" >> $client_config
    fi
    
    cat >> $client_config << 'EOF'
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/client1.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/client1.key)
</key>
EOF
    
    log_info "客户端配置文件已生成: $client_config"
}

# 显示安装结果
show_result() {
    echo ""
    echo "=========================================="
    echo "   OpenVPN 安装完成!"
    echo "=========================================="
    echo ""
    echo "服务器信息:"
    echo "  - 服务器IP: $SERVER_IP"
    echo "  - 监听端口: $SERVER_PORT"
    echo "  - 协议类型: $SERVER_PROTO"
    echo "  - VPN网段: $VPN_NETWORK/$VPN_NETMASK"
    if [ "$USE_IP_POOL" = "yes" ]; then
        echo "  - 客户端IP池: $CLIENT_IP_START - $CLIENT_IP_END"
    else
        echo "  - 客户端IP: 自动分配"
    fi
    echo ""
    echo "客户端配置文件位置:"
    echo "  /root/client.ovpn"
    echo ""
    echo "认证信息 (使用系统root账户):"
    echo "  - 用户名: root"
    echo "  - 密码: <系统root密码>"
    echo ""
    echo "服务管理命令:"
    echo "  - 查看状态: systemctl status openvpn@server"
    echo "  - 重启服务: systemctl restart openvpn@server"
    echo "  - 查看日志: journalctl -u openvpn@server -f"
    echo ""
    echo "客户端连接:"
    echo "  1. 下载 /root/client.ovpn 到客户端设备"
    echo "  2. 使用OpenVPN客户端导入配置文件"
    echo "  3. 输入系统root用户名和密码连接"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "   OpenVPN 服务器一键安装脚本"
    echo "   兼容iKuai路由器及低版本客户端"
    echo "=========================================="
    echo ""
    
    check_root
    detect_os
    interactive_config
    install_dependencies
    setup_pki
    create_server_config
    setup_networking
    start_openvpn
    generate_client_config
    show_result
    
    log_info "安装完成!"
}

# 运行主函数
main