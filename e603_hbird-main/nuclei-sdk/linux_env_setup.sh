#!/bin/bash
# linux_env_all.sh - 设置完整的开发环境

echo "=========================================="
echo "设置完整的 RISC-V 开发环境"
echo "=========================================="

# 设置 OpenOCD
echo ""
echo "1. 设置 OpenOCD..."
if [ -f "linux_openocd.sh" ]; then
    source linux_openocd.sh
else
    echo "linux_openocd.sh 不存在"
fi

echo ""
echo "2. 设置 GCC 工具链..."
if [ -f "linux_gcc.sh" ]; then
    source linux_gcc.sh
else
    echo "linux_gcc.sh 不存在"
fi

echo ""
echo "3. 修复openocd权限..."
if [ -f "linux_udev.sh" ]; then
	source linux_udev.sh
else
	echo "linux_udev.sh 不存在"
fi

echo ""
echo "=========================================="
echo "环境设置完成！"
echo ""
echo "🔍 验证所有工具:"
echo "   which riscv64-unknown-elf-gcc"
echo "   which openocd"
echo "   which riscv64-unknown-elf-gdb"
echo ""
echo "🚀 完整工作流程:"
echo "   1. 编译: make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval all"
echo "   2. 下载: make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval DOWNLOAD=flash upload"
echo "   3. 调试: make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval DOWNLOAD=ilm debug"
echo "=========================================="
