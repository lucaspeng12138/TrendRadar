#!/bin/bash

# TrendRadar Cron 任务移除脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   TrendRadar Cron 任务移除            ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_COMMAND="$SCRIPT_DIR/run-periodic.sh"

echo -e "${BLUE}📍 项目目录: $SCRIPT_DIR${NC}"
echo ""

# 检查是否有 TrendRadar 相关的 cron 任务
EXISTING_CRON=$(crontab -l 2>/dev/null | grep -F "$CRON_COMMAND" || true)

if [ -z "$EXISTING_CRON" ]; then
    echo -e "${YELLOW}ℹ️  未找到相关的定时任务${NC}"
    echo ""
    echo "📋 当前所有定时任务:"
    crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' || echo "   无定时任务"
    echo ""
    exit 0
fi

echo "🔍 找到以下相关任务:"
echo "$EXISTING_CRON"
echo ""

read -p "确认要移除这些任务吗? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}ℹ️  操作取消${NC}"
    exit 0
fi

# 备份当前 crontab
echo "📦 备份当前 crontab..."
crontab -l > "$SCRIPT_DIR/crontab_backup_remove_$(date +%Y%m%d_%H%M%S).txt" 2>/dev/null || true
echo -e "${GREEN}✅ 备份完成${NC}"

# 移除 TrendRadar 相关的 cron 任务
echo "🗑️  移除定时任务..."
crontab -l 2>/dev/null | grep -v -F "$CRON_COMMAND" | crontab -

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Cron 任务移除成功！${NC}"
    echo ""
    echo "📋 剩余定时任务:"
    crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' || echo "   无定时任务"
    echo ""
else
    echo -e "${RED}❌ Cron 任务移除失败${NC}"
    echo "请手动检查 crontab"
    exit 1
fi
