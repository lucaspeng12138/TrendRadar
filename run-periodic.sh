#!/bin/bash

# TrendRadar 定期运行脚本
# 每4小时运行一次 main.py

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 设置日志文件
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/trendradar_$(date +\%Y\%m\%d_\%H\%M\%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 开始日志
log "=== TrendRadar 定期任务开始 ==="
log "工作目录: $SCRIPT_DIR"
log "日志文件: $LOG_FILE"

# 检查配置文件
if [ ! -f "config/config.yaml" ] || [ ! -f "config/frequency_words.txt" ]; then
    log "❌ 错误: 配置文件缺失"
    log "请确保以下文件存在:"
    log "  • config/config.yaml"
    log "  • config/frequency_words.txt"
    exit 1
fi

log "✅ 环境检查通过，开始执行分析..."

# 运行主程序并记录输出
log "执行命令: python3 main.py"
python3 main.py 2>&1 | while IFS= read -r line; do
    log "$line"
done

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log "✅ TrendRadar 任务执行成功"
else
    log "❌ TrendRadar 任务执行失败 (退出码: $EXIT_CODE)"
fi

log "=== TrendRadar 定期任务结束 ==="
log ""

exit $EXIT_CODE
