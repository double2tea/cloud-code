#!/bin/bash

# Zeabur 部署脚本
# 使用方法: ./deploy-zeabur.sh [init|deploy|status|logs|env]

set -e

PROJECT_NAME="cloud-code"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_zeabur_cli() {
    if ! command -v zeabur &> /dev/null; then
        log_error "Zeabur CLI 未安装"
        log_info "请访问 https://zeabur.com/docs/deploy/cli 安装 Zeabur CLI"
        log_info "或运行: npm install -g @zeabur/cli"
        exit 1
    fi
    log_success "Zeabur CLI 已安装"
}

check_login() {
    if ! zeabur auth whoami &> /dev/null; then
        log_error "未登录 Zeabur"
        log_info "请运行: zeabur auth login"
        exit 1
    fi
    log_success "已登录 Zeabur"
}

init_project() {
    log_info "初始化 Zeabur 项目..."

    # 检查是否已经初始化
    if [ -f ".zeabur/project.json" ]; then
        log_warn "项目已经初始化"
        return
    fi

    # 创建 .zeabur 目录
    mkdir -p .zeabur

    # 初始化项目
    zeabur project create "$PROJECT_NAME" || true

    log_success "项目初始化完成"
}

set_environment() {
    log_info "设置环境变量..."

    # 设置环境变量
    zeabur env set NODE_ENV=production
    zeabur env set PORT=2633

    # S3/R2 配置
    zeabur env set S3_ENDPOINT="https://4fe3598337e00d68ea219bd315055543.r2.cloudflarestorage.com"
    zeabur env set S3_BUCKET="cloud-code"
    zeabur env set S3_ACCESS_KEY_ID="c5846289fce4d82bc14425ba7b9d9b97"
    zeabur env set S3_SECRET_ACCESS_KEY="5084fe65a9e7d8f2abbcac916d958607838ad5c4aee9a87b0e09ae933dbd5fa5"
    zeabur env set S3_REGION="auto"
    zeabur env set S3_PATH_STYLE="false"
    zeabur env set S3_PREFIX="cloud-code"

    log_success "环境变量设置完成"
}

deploy_service() {
    log_info "部署到 Zeabur..."

    # 使用 Zeabur 专用的 Dockerfile
    cp Dockerfile.zeabur Dockerfile

    # 部署服务
    zeabur deploy

    # 恢复原始 Dockerfile
    git checkout Dockerfile 2>/dev/null || true

    log_success "部署完成"
    log_info "请查看 Zeabur 控制台获取访问地址"
}

show_status() {
    log_info "服务状态:"
    zeabur service list
}

show_logs() {
    log_info "显示服务日志..."
    zeabur logs
}

show_help() {
    echo "Zeabur 部署脚本"
    echo ""
    echo "使用方法:"
    echo "  ./deploy-zeabur.sh [命令]"
    echo ""
    echo "可用命令:"
    echo "  init      初始化项目"
    echo "  env       设置环境变量"
    echo "  deploy    部署服务"
    echo "  status    查看状态"
    echo "  logs      查看日志"
    echo "  help      显示帮助"
    echo ""
    echo "完整部署流程:"
    echo "  1. ./deploy-zeabur.sh init"
    echo "  2. ./deploy-zeabur.sh env"
    echo "  3. ./deploy-zeabur.sh deploy"
}

# 主逻辑
case "${1:-help}" in
    init)
        check_zeabur_cli
        check_login
        init_project
        ;;
    env)
        check_zeabur_cli
        check_login
        set_environment
        ;;
    deploy)
        check_zeabur_cli
        check_login
        deploy_service
        ;;
    status)
        check_zeabur_cli
        check_login
        show_status
        ;;
    logs)
        check_zeabur_cli
        check_login
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        show_help
        exit 1
        ;;
esac