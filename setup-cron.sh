#!/bin/bash

# TrendRadar Cron 任务设置脚本
# 设置每4小时运行一次 main.py

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   TrendRadar Cron 任务设置            ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查运行脚本是否存在
if [ ! -f "$SCRIPT_DIR/run-periodic.sh" ]; then
    echo -e "${RED}❌ 错误: 运行脚本不存在: $SCRIPT_DIR/run-periodic.sh${NC}"
    echo "请先确保 run-periodic.sh 文件存在"
    exit 1
fi

# 检查运行脚本是否有执行权限
if [ ! -x "$SCRIPT_DIR/run-periodic.sh" ]; then
    echo -e "${YELLOW}⚠️  警告: 运行脚本没有执行权限，正在修复...${NC}"
    chmod +x "$SCRIPT_DIR/run-periodic.sh"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 错误: 无法设置执行权限${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ 执行权限已设置${NC}"
fi

echo -e "${BLUE}📍 项目目录: $SCRIPT_DIR${NC}"
echo ""

# Cron 任务配置
CRON_TIME="0 */4 * * *"  # 每4小时运行一次（00:00, 04:00, 08:00, 12:00, 16:00, 20:00）
CRON_COMMAND="$SCRIPT_DIR/run-periodic.sh"

echo "📋 Cron 任务配置:"
echo -e "   时间: ${BLUE}$CRON_TIME${NC} (每4小时)"
echo -e "   命令: ${BLUE}$CRON_COMMAND${NC}"
echo ""

# 检查是否已有相同的 cron 任务
EXISTING_CRON=$(crontab -l 2>/dev/null | grep -F "$CRON_COMMAND" || true)

if [ -n "$EXISTING_CRON" ]; then
    echo -e "${YELLOW}⚠️  发现已存在的相同任务:${NC}"
    echo "   $EXISTING_CRON"
    echo ""
    read -p "是否要替换现有的任务? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  操作取消${NC}"
        exit 0
    fi
fi

# 备份当前 crontab
echo "📦 备份当前 crontab..."
crontab -l > "$SCRIPT_DIR/crontab_backup_$(date +%Y%m%d_%H%M%S).txt" 2>/dev/null || true
echo -e "${GREEN}✅ 备份完成${NC}"

# 移除已存在的相同任务（如果有）
if [ -n "$EXISTING_CRON" ]; then
    echo "🔄 移除旧任务..."
    crontab -l 2>/dev/null | grep -v -F "$CRON_COMMAND" | crontab -
fi

# 添加新的 cron 任务
echo "➕ 添加新的定时任务..."
(crontab -l 2>/dev/null; echo "$CRON_TIME $CRON_COMMAND") | crontab -

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Cron 任务设置成功！${NC}"
    echo ""
    echo "📋 当前定时任务列表:"
    crontab -l | grep -v '^#' | grep -v '^$'
    echo ""
    echo "🔍 日志文件位置: $SCRIPT_DIR/logs/"
    echo ""
    echo "💡 提示:"
    echo "  • 任务将在下个整4小时时间点开始执行"
    echo "  • 查看日志: tail -f $SCRIPT_DIR/logs/*.log"
    echo "  • 停止任务: ./remove-cron.sh"
    echo ""
else
    echo -e "${RED}❌ Cron 任务设置失败${NC}"
    echo "请检查权限或手动设置"
    exit 1
fi
