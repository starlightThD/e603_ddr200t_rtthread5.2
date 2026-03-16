#!/bin/bash
# OpenOCD 包装脚本 - 自动处理权限问题

# 默认配置文件
DEFAULT_CONFIG="../../../SoC/evalsoc/Board/nuclei_fpga_eval/openocd_evalsoc.cfg"

# 使用传入的配置文件或默认配置
CONFIG_FILE="${1:-$DEFAULT_CONFIG}"

echo "使用配置文件: $CONFIG_FILE"

# 检查设备是否存在
if ! lsusb | grep -q "0403:6010"; then
    echo "❌ 未找到 FTDI 设备 (0403:6010)"
    echo "请检查开发板连接"
    exit 1
fi

# 尝试普通用户模式
echo "尝试以普通用户运行 OpenOCD..."
if openocd -f "$CONFIG_FILE" 2>/dev/null; then
    exit 0
fi

# 如果失败，检查是否是权限问题
echo "普通用户模式失败，可能是权限问题"
echo "请确保:"
echo "1. 已运行 fix_ftdi_permissions.sh"
echo "2. 已重新登录或运行 newgrp plugdev"
echo ""
echo "临时解决方案：使用 sudo（需要输入密码）"
sudo openocd -f "$CONFIG_FILE"
