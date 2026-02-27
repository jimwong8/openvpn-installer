# 快速入门指南

本指南将帮助你快速设置和使用全栈开发环境。

## 1. 环境要求

- Docker 20.10.0 或更高版本
- Docker Compose 2.0.0 或更高版本
- 至少 4GB 可用内存
- 至少 20GB 可用磁盘空间

## 2. 安装步骤

### 2.1 克隆仓库

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2.2 构建开发环境

基本构建：
```bash
./scripts/build.sh
```

自定义构建：
```bash
./scripts/build.sh -u myuser -i 1001 -g 1001 -t dev
```

### 2.3 启动环境

基本启动：
```bash
./scripts/run.sh
```

项目特定启动：
```bash
# Node.js 项目
./scripts/run.sh -p nodejs

# Python 项目
./scripts/run.sh -p python

# Java 项目
./scripts/run.sh -p java

# Go 项目
./scripts/run.sh -p go
```

## 3. 开发环境使用

### 3.1 Node.js 开发

```bash
# 创建新项目
cd /workspace/projects/nodejs
npm init

# 安装依赖
npm install express

# 运行应用
npm start
```

### 3.2 Python 开发

```bash
# 激活虚拟环境
cd /workspace/projects/python
source venv/bin/activate

# 安装依赖
pip install flask

# 运行应用
python app.py
```

### 3.3 Java 开发

```bash
# 创建 Maven 项目
cd /workspace/projects/java
mvn archetype:generate

# 构建项目
mvn package

# 运行应用
java -jar target/myapp.jar
```

### 3.4 Go 开发

```bash
# 初始化模块
cd /workspace/projects/go/src/myapp
go mod init myapp

# 构建项目
go build

# 运行应用
./myapp
```

## 4. 常用操作

### 4.1 端口映射

默认映射的端口：
- 3000: Node.js
- 5000: Python
- 8080: Java
- 8000: Go
- 9229: Node.js 调试

### 4.2 文件同步

工作目录已通过数据卷映射：
- `workspace/projects/nodejs`: Node.js 项目目录
- `workspace/projects/python`: Python 项目目录
- `workspace/projects/java`: Java 项目目录
- `workspace/projects/go`: Go 项目目录

### 4.3 包管理缓存

以下目录已配置持久化：
- npm: node_modules
- pip: ~/.cache/pip
- Go: ~/.cache/go-build
- Maven: ~/.m2
- Gradle: ~/.gradle

## 5. 开发工具

### 5.1 Visual Studio Code

推荐的插件：
- Remote - Containers
- Docker
- 语言特定插件

### 5.2 Git 配置

Git 已预配置：
- 用户信息
- 别名
- 颜色支持
- 默认编辑器

### 5.3 Vim 配置

已优化的 Vim 配置：
- 语法高亮
- 自动缩进
- 文件类型检测
- 常用快捷键

## 6. 调试技巧

### 6.1 查看日志

```bash
# 查看容器日志
docker logs fullstack-dev

# 查看应用日志
docker exec -it fullstack-dev tail -f /var/log/app.log
```

### 6.2 进入容器

```bash
# 交互式 shell
docker exec -it fullstack-dev bash

# 特定用户
docker exec -it -u developer fullstack-dev bash
```

### 6.3 重启服务

```bash
# 重启容器
docker-compose restart

# 重新构建并启动
docker-compose up -d --build
```

## 7. 故障排除

### 7.1 常见问题

1. 权限问题
   - 检查用户 UID/GID
   - 确认目录权限
   - 使用 sudo 命令

2. 网络问题
   - 验证端口映射
   - 检查防火墙设置
   - 确认网络配置

3. 内存问题
   - 检查容器资源限制
   - 监控内存使用
   - 清理未使用资源

### 7.2 获取帮助

- 查看详细文档：`README.md`
- 提交 Issue
- 参考在线资源

## 8. 最佳实践

1. 定期更新
   - 更新基础镜像
   - 更新开发工具
   - 更新依赖包

2. 安全建议
   - 使用非 root 用户
   - 定期更新安全补丁
   - 遵循最小权限原则

3. 性能优化
   - 使用数据卷缓存
   - 优化构建过程
   - 合理配置资源限制