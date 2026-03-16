#!/bin/bash
# fix_ftdi_permissions.sh - 自动修复 FTDI 设备权限

echo "=========================================="
echo "自动修复 FTDI 设备权限"
echo "=========================================="

# 检查是否以普通用户运行
if [ "$EUID" -eq 0 ]; then
    echo "❌ 请不要以 root 用户运行此脚本"
    echo "请以普通用户运行: ./fix_ftdi_permissions.sh"
    exit 1
fi

echo "当前用户: $USER"
echo ""

# 1. 创建 udev 规则
echo "1. 创建 udev 规则..."
RULES_FILE="/etc/udev/rules.d/99-ftdi-nuclei.rules"

sudo tee "$RULES_FILE" << 'EOF'
# Nuclei 开发板 FTDI 设备权限规则
# FTDI FT2232C/D/H (0403:6010) 和其他常见 FTDI 设备

# USB 设备权限
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="0666", GROUP="plugdev", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6011", MODE="0666", GROUP="plugdev", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6014", MODE="0666", GROUP="plugdev", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# 所有 FTDI 设备通用规则
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", MODE="0666", GROUP="plugdev", TAG+="uaccess"

# 串口设备权限
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="plugdev", TAG+="uaccess"
KERNEL=="ttyUSB*", MODE="0666", GROUP="plugdev", TAG+="uaccess"
KERNEL=="ttyACM*", MODE="0666", GROUP="plugdev", TAG+="uaccess"
EOF

echo "✅ 已创建规则文件: $RULES_FILE"

# 2. 重新加载 udev 规则
echo ""
echo "2. 重新加载 udev 规则..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# 3. 添加用户到必要组
echo ""
echo "3. 添加用户到必要组..."
for group in plugdev dialout; do
    if ! groups $USER | grep -q "\b$group\b"; then
        echo "添加 $USER 到 $group 组..."
        sudo usermod -a -G $group $USER
        echo "✅ 已添加到 $group 组"
    else
        echo "✅ $USER 已在 $group 组中"
    fi
done

# 4. 安装必要的库
echo ""
echo "4. 检查并安装必要的库..."
REQUIRED_PKGS="libftdi1 libftdi1-2 libusb-1.0-0"

for pkg in $REQUIRED_PKGS; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "安装 $pkg..."
        sudo apt-get install -y $pkg >/dev/null 2>&1
        echo "✅ 已安装 $pkg"
    else
        echo "✅ $pkg 已安装"
    fi
done

# 5. 创建组权限立即生效的脚本
echo ""
echo "5. 创建组权限生效脚本..."
cat > /tmp/activate_groups.sh << 'EOF'
#!/bin/bash
# 激活组权限
echo "激活组权限..."
newgrp plugdev << 'END'
newgrp dialout << 'END2'
echo "组权限已激活"
echo "现在可以正常使用 OpenOCD 了"
END2
END
EOF

chmod +x /tmp/activate_groups.sh

# 6. 创建 OpenOCD 包装脚本
echo ""
echo "6. 创建 OpenOCD 包装脚本..."
cat > openocd_wrapper.sh << 'EOF'
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
EOF

chmod +x openocd_wrapper.sh

# 7. 测试当前权限
echo ""
echo "7. 测试当前设备权限..."
echo "当前 USB 设备:"
lsusb | grep "0403:" || echo "未找到 FTDI 设备"

echo ""
echo "设备文件权限:"
ls -la /dev/ttyUSB* 2>/dev/null || echo "未找到 /dev/ttyUSB* 设备"

# 8. 验证修复
echo ""
echo "8. 验证修复..."
echo "要验证修复是否成功，请:"
echo "1. 重新拔插开发板"
echo "2. 运行: source /tmp/activate_groups.sh"
echo "3. 测试: openocd -f ../../../SoC/evalsoc/Board/nuclei_fpga_eval/openocd_evalsoc.cfg"

echo ""
echo "=========================================="
echo "修复完成！"
echo ""
echo "📋 重要提示:"
echo "1. 需要重新登录系统使组权限完全生效"
echo "2. 或者运行: newgrp plugdev"
echo "3. 然后重新拔插开发板"
echo ""
echo "🚀 快捷命令:"
echo "   激活组权限: source /tmp/activate_groups.sh"
echo "   使用包装脚本: ./openocd_wrapper.sh"
echo "   测试连接: openocd -f ../../../SoC/evalsoc/Board/nuclei_fpga_eval/openocd_evalsoc.cfg"
echo "=========================================="

