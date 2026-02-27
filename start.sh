#!/bin/bash

# 分布式下载集群启动脚本
# Distributed Download Cluster Startup Script

echo "🚀 启动分布式下载集群..."
echo "Starting Distributed Download Cluster..."

# 检查Docker和Docker Compose是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    echo "❌ Docker is not installed, please install Docker first"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，请先安装Docker Compose"
    echo "❌ Docker Compose is not installed, please install Docker Compose first"
    exit 1
fi

# 停止并清理现有容器
echo "🧹 清理现有容器..."
echo "Cleaning up existing containers..."
docker-compose down

# 构建并启动所有服务
echo "🔨 构建并启动服务..."
echo "Building and starting services..."
docker-compose up --build -d

# 等待服务启动
echo "⏳ 等待服务启动..."
echo "Waiting for services to start..."
sleep 10

# 显示服务状态
echo "📊 服务状态："
echo "Service Status:"
docker-compose ps

echo ""
echo "✅ 分布式下载集群已启动！"
echo "✅ Distributed Download Cluster is running!"
echo ""
echo "🌐 访问地址 | Access URLs:"
echo "  - Web界面 | Web Interface: http://localhost:5000"
echo "  - Grafana监控 | Grafana Dashboard: http://localhost:3000"
echo "  - Prometheus指标 | Prometheus Metrics: http://localhost:9090"
echo ""
echo "📖 使用说明 | Usage Guide:"
echo "  1. 打开Web界面添加下载任务"
echo "  2. 查看Grafana监控面板了解系统状态"
echo "  3. 使用API接口进行自动化操作"
echo ""
echo "🛑 停止服务 | Stop Services:"
echo "  docker-compose down"