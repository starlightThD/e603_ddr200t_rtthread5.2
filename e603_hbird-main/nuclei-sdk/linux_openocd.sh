#!/bin/bash
# linux_openocd.sh - 设置 OpenOCD 环境

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLCHAIN_PATH="$PROJECT_ROOT/toolchain"
OPENOCD_BIN_DIR="$TOOLCHAIN_PATH/openocd/bin"
OPENOCD_PATH="$OPENOCD_BIN_DIR/openocd"

echo "=========================================="
echo "OpenOCD 环境设置脚本"
echo "=========================================="
echo "脚本目录: $SCRIPT_DIR"
echo "项目根目录: $PROJECT_ROOT"
echo "工具链路径: $TOOLCHAIN_PATH"
echo "OpenOCD 路径: $OPENOCD_BIN_DIR"
echo "=========================================="

# 检查 OpenOCD 目录是否存在
if [ ! -d "$OPENOCD_BIN_DIR" ]; then
    echo "❌ 错误: OpenOCD 目录不存在: $OPENOCD_BIN_DIR"
    echo "请确保 openocd 安装在: $TOOLCHAIN_PATH/openocd/"
    exit 1
fi

# 检查 OpenOCD 可执行文件
if [ ! -f "$OPENOCD_PATH" ]; then
    echo "❌ 错误: OpenOCD 可执行文件不存在: $OPENOCD_PATH"
    echo "目录内容:"
    ls -la "$OPENOCD_BIN_DIR/"
    echo ""
    echo "尝试查找 openocd..."
    FOUND_OPENOCD=$(find "$OPENOCD_BIN_DIR" -name "openocd" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND_OPENOCD" ]; then
        echo "✅ 找到 OpenOCD: $FOUND_OPENOCD"
        OPENOCD_PATH="$FOUND_OPENOCD"
    else
        echo "❌ 未找到 openocd 可执行文件"
        exit 1
    fi
fi

echo "✅ OpenOCD 存在: $OPENOCD_PATH"

# 设置环境变量
export PATH="$OPENOCD_BIN_DIR:$PATH"
export OPENOCD_PATH="$OPENOCD_PATH"
export OPENOCD_BIN_DIR="$OPENOCD_BIN_DIR"

# 添加库路径
if [ -d "$TOOLCHAIN_PATH/openocd/bin" ]; then
    export LD_LIBRARY_PATH="$TOOLCHAIN_PATH/openocd/bin:$LD_LIBRARY_PATH"
    echo "✅ 已添加库路径: $TOOLCHAIN_PATH/openocd/bin"
fi

# 检查 OpenOCD 脚本目录
OPENOCD_SCRIPT_DIR="$TOOLCHAIN_PATH/openocd/scripts"
if [ -d "$OPENOCD_SCRIPT_DIR" ]; then
    export OPENOCD_SCRIPTS="$OPENOCD_SCRIPT_DIR"
    echo "✅ OpenOCD 脚本目录: $OPENOCD_SCRIPT_DIR"
    echo "   已设置 OPENOCD_SCRIPTS 环境变量"
else
    echo "⚠️  OpenOCD 脚本目录不存在: $OPENOCD_SCRIPT_DIR"
    echo "   可能需要手动设置 OPENOCD_SCRIPTS"
fi

echo ""
echo "📋 环境变量已设置:"
echo "   PATH 已添加: $OPENOCD_BIN_DIR"
echo "   OPENOCD_PATH: $OPENOCD_PATH"
echo "   OPENOCD_BIN_DIR: $OPENOCD_BIN_DIR"
if [ -n "$OPENOCD_SCRIPTS" ]; then
    echo "   OPENOCD_SCRIPTS: $OPENOCD_SCRIPTS"
fi
if [ -n "$LD_LIBRARY_PATH" ]; then
    echo "   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
fi

echo ""
echo "🔍 验证设置:"
echo "1. 查找 openocd:"
which openocd 2>/dev/null || echo "   ❌ 在 PATH 中未找到 openocd"

echo ""
echo "2. OpenOCD 版本:"
if "$OPENOCD_PATH" --version 2>/dev/null | head -1; then
    echo "   ✅ OpenOCD 版本检查成功"
else
    echo "   ❌ 无法获取 OpenOCD 版本"
fi

echo ""
echo "3. 检查 OpenOCD 依赖:"
if ldd "$OPENOCD_PATH" 2>/dev/null | grep -q "not found"; then
    echo "   ⚠️  OpenOCD 有未满足的依赖:"
    ldd "$OPENOCD_PATH" | grep "not found"
    echo ""
    echo "   可能需要安装以下库:"
    echo "   sudo apt-get install libftdi1 libhidapi-hidraw0 libudev1 libusb-1.0-0"
else
    echo "   ✅ OpenOCD 依赖检查通过"
fi

echo ""
echo "4. 测试 OpenOCD 命令:"
echo "   运行: openocd --help"
echo "   按 Ctrl+C 停止"

echo ""
echo "=========================================="
echo "OpenOCD 环境设置完成！"
echo ""
echo "🚀 现在可以使用以下命令:"
echo ""
echo "1. 独立运行 OpenOCD:"
echo "   openocd -f ../../../SoC/evalsoc/Board/nuclei_fpga_eval/openocd_evalsoc.cfg"
echo ""
echo "2. 与 make 命令一起使用:"
echo "   make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval DOWNLOAD=ilm download"
echo ""
echo "3. 调试模式:"
echo "   make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval DOWNLOAD=ilm debug"
echo ""
echo "🔧 如果 make 命令找不到 openocd，请确保:"
echo "   1. 先运行: source linux_openocd.sh"
echo "   2. 再运行: source linux_setup.sh (如果需要 GCC 工具链)"
echo "=========================================="

# 创建快捷命令
cat > /tmp/openocd_quick_$$.sh << EOF
#!/bin/bash
# OpenOCD 快捷命令
export PATH=$OPENOCD_BIN_DIR:\$PATH
export LD_LIBRARY_PATH=$TOOLCHAIN_PATH/openocd/bin:\$LD_LIBRARY_PATH
exec openocd "\$@"
EOF
chmod +x /tmp/openocd_quick_$$.sh

echo ""
echo "💡 快捷命令已创建: /tmp/openocd_quick_$$.sh"
echo "   使用: /tmp/openocd_quick_$$.sh [参数]"