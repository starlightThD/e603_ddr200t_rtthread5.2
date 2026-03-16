#!/bin/bash
# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLCHAIN_PATH="$PROJECT_ROOT/toolchain"
TOOLS_BIN_DIR="$TOOLCHAIN_PATH/gcc/bin"
OPENOCD_BIN_DIR="$TOOLCHAIN_PATH/openocd/bin"
GCC_PATH="$TOOLS_BIN_DIR/riscv64-unknown-elf-gcc"
GDB_PATH="$TOOLS_BIN_DIR/riscv64-unknown-elf-gdb"

echo "脚本目录: $SCRIPT_DIR"
echo "项目根目录: $PROJECT_ROOT"
echo "工具链路径: $TOOLCHAIN_PATH"
echo "=========================================="

# 检查工具链目录是否存在
if [ ! -d "$TOOLCHAIN_PATH" ]; then
    echo "错误: 工具链目录不存在: $TOOLCHAIN_PATH"
    echo "请确保项目结构正确，toolchain 目录应该位于项目根目录下"
    exit 1
fi

# 检查 GCC 编译器是否存在
if [ ! -f "$GCC_PATH" ]; then
    echo "错误: GCC 编译器不存在: $GCC_PATH"
    echo "请检查工具链是否已正确安装"
    exit 1
fi

echo "工具链目录存在"
echo "GCC 编译器存在: $GCC_PATH"

# 设置环境变量 - 添加整个 bin 目录到 PATH
export PATH="$TOOLS_BIN_DIR:$PATH"
export RISCV_TOOLCHAIN_PATH="$TOOLCHAIN_PATH/gcc"
export CROSS_COMPILE="$TOOLS_BIN_DIR/riscv64-unknown-elf-"

# 设置其他常用的工具链环境变量
export RISCV_PREFIX="riscv64-unknown-elf-"
export RISCV_CC="${CROSS_COMPILE}gcc"
export RISCV_CXX="${CROSS_COMPILE}g++"
export RISCV_OBJCOPY="${CROSS_COMPILE}objcopy"
export RISCV_OBJDUMP="${CROSS_COMPILE}objdump"
export RISCV_READELF="${CROSS_COMPILE}readelf"
export RISCV_AR="${CROSS_COMPILE}ar"
export RISCV_AS="${CROSS_COMPILE}as"
export RISCV_LD="${CROSS_COMPILE}ld"
export RISCV_NM="${CROSS_COMPILE}nm"
export RISCV_RANLIB="${CROSS_COMPILE}ranlib"
export RISCV_STRIP="${CROSS_COMPILE}strip"
export RISCV_SIZE="${CROSS_COMPILE}size"

# 设置 LLVM 相关环境变量
export LLVM_PATH="$TOOLCHAIN_PATH/gcc"
export CLANG="${CROSS_COMPILE}clang"
export CLANGPP="${CROSS_COMPILE}clang++"
export LLVM_AR="${CROSS_COMPILE}llvm-ar"
export LLVM_NM="${CROSS_COMPILE}llvm-nm"
export LLVM_OBJCOPY="${CROSS_COMPILE}llvm-objcopy"
export LLVM_OBJDUMP="${CROSS_COMPILE}llvm-objdump"
export LLVM_SIZE="${CROSS_COMPILE}llvm-size"
export LLVM_STRIP="${CROSS_COMPILE}llvm-strip"

# 添加库路径
echo ""
echo "添加库路径:"
LIB_PATHS=(
    "$TOOLCHAIN_PATH/gcc/lib64"
    "$TOOLCHAIN_PATH/gcc/lib"
    "$TOOLCHAIN_PATH/gcc/riscv64-unknown-elf/lib"
)

for lib_path in "${LIB_PATHS[@]}"; do
    if [ -d "$lib_path" ]; then
        export LD_LIBRARY_PATH="$lib_path:$LD_LIBRARY_PATH"
        echo "   ✅ 已添加: $lib_path"
    fi
done

echo ""
echo "环境变量已设置:"
echo "   PATH 已添加: $TOOLS_BIN_DIR"
echo "   RISCV_TOOLCHAIN_PATH: $RISCV_TOOLCHAIN_PATH"
echo "   CROSS_COMPILE: $CROSS_COMPILE"
if [ -n "$LD_LIBRARY_PATH" ]; then
    echo "   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
fi
echo ""

# 验证设置 - 检查多个工具
echo "验证工具链:"
echo "1. 编译器信息:"
which riscv64-unknown-elf-gcc
file "$GCC_PATH"
echo ""

# 检查工具链类型
echo "2. 工具链类型检测:"
if [ -L "$GCC_PATH" ]; then
    LINK_TARGET=$(readlink "$GCC_PATH")
    if echo "$LINK_TARGET" | grep -q "clang"; then
        echo "   ✅ 检测到 Clang/LLVM-based 工具链"
        echo "   riscv64-unknown-elf-gcc -> $LINK_TARGET"
    else
        echo "   ✅ 检测到 GNU GCC 工具链"
        echo "   riscv64-unknown-elf-gcc -> $LINK_TARGET"
    fi
elif [ -f "$GCC_PATH" ]; then
    if file "$GCC_PATH" | grep -q "ELF"; then
        echo "   ✅ 检测到 GNU GCC 工具链 (ELF 可执行文件)"
    else
        echo "   ℹ️  无法确定工具链类型"
    fi
fi
echo ""

echo "3. 可用的 RISC-V 工具:"
RISCV_TOOLS=$(ls "$TOOLS_BIN_DIR" | grep "^riscv64-unknown-elf-" | sort)
echo "$RISCV_TOOLS" | xargs -n 4 echo "   "

echo ""
echo "4. 验证关键工具:"
declare -A key_tools=(
    ["编译器"]="riscv64-unknown-elf-gcc"
    ["C++编译器"]="riscv64-unknown-elf-g++"
    ["调试器"]="riscv64-unknown-elf-gdb"
    ["汇编器"]="riscv64-unknown-elf-as"
    ["链接器"]="riscv64-unknown-elf-ld"
    ["归档工具"]="riscv64-unknown-elf-ar"
    ["对象复制"]="riscv64-unknown-elf-objcopy"
    ["对象转储"]="riscv64-unknown-elf-objdump"
    ["ELF读取"]="riscv64-unknown-elf-readelf"
    ["大小查看"]="riscv64-unknown-elf-size"
)

for tool_desc in "${!key_tools[@]}"; do
    tool="${key_tools[$tool_desc]}"
    if [ -f "$TOOLS_BIN_DIR/$tool" ]; then
        echo "   ✅ $tool_desc: $tool (存在)"
    else
        echo "   ❌ $tool_desc: $tool (不存在)"
    fi
done

echo ""
echo "5. 检查 GDB 依赖:"
if [ -f "$GDB_PATH" ]; then
    echo "   GDB 路径: $GDB_PATH"
    # 检查依赖
    if ldd "$GDB_PATH" 2>/dev/null | grep -q "not found"; then
        echo "   ⚠️  GDB 有未满足的依赖:"
        ldd "$GDB_PATH" | grep "not found"
        echo ""
        echo "   尝试自动修复..."
    else
        echo "   ✅ GDB 依赖检查通过"
    fi
else
    echo "   ⚠️  GDB 不存在于工具链中"
fi

echo ""
echo "6. 检查并修复库依赖..."
NCURSES_LIB="/usr/lib/x86_64-linux-gnu/libncursesw.so.5"
if [ ! -e "$NCURSES_LIB" ]; then
    echo "   ⚠️  缺少 libncursesw.so.5，尝试创建符号链接..."
    if [ -f "/usr/lib/x86_64-linux-gnu/libncursesw.so.6" ]; then
        sudo ln -sf /usr/lib/x86_64-linux-gnu/libncursesw.so.6 "$NCURSES_LIB" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "   ✅ 已创建 $NCURSES_LIB -> libncursesw.so.6"
        else
            echo "   ❌ 需要 sudo 权限创建符号链接"
            echo "   请手动运行: sudo ln -sf /usr/lib/x86_64-linux-gnu/libncursesw.so.6 $NCURSES_LIB"
        fi
    else
        echo "   ❌ 无法创建符号链接，libncursesw.so.6 不存在"
    fi
else
    echo "   ✅ libncursesw.so.5 已存在"
fi

# 检查 libtinfo
TINFO_LIB="/usr/lib/x86_64-linux-gnu/libtinfo.so.5"
if [ ! -e "$TINFO_LIB" ]; then
    if [ -f "/usr/lib/x86_64-linux-gnu/libtinfo.so.6" ]; then
        sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 "$TINFO_LIB" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "   ✅ 已创建 $TINFO_LIB -> libtinfo.so.6"
        else
            echo "   ❌ 需要 sudo 权限创建符号链接"
            echo "   请手动运行: sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 $TINFO_LIB"
        fi
    fi
else
    echo "   ✅ libtinfo.so.5 已存在"
fi

echo ""
echo "7. 验证修复后 GDB 依赖..."
if [ -f "$GDB_PATH" ]; then
    if ldd "$GDB_PATH" 2>/dev/null | grep -q "not found"; then
        echo "   ❌ GDB 仍有未满足的依赖"
        ldd "$GDB_PATH" | grep "not found"
        echo ""
        echo "   尝试使用 LD_PRELOAD 解决方案..."
        
        # 创建修复脚本
        FIX_SCRIPT="/tmp/riscv_gdb_fix_$$.sh"
        cat > "$FIX_SCRIPT" << 'EOF'
#!/bin/bash
# 自动修复 GDB 依赖问题的包装脚本
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libncursesw.so.6:/usr/lib/x86_64-linux-gnu/libtinfo.so.6
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
exec /home/thd/CS/Project/ddr200t/toolchain/gcc/bin/riscv64-unknown-elf-gdb "$@"
EOF
        chmod +x "$FIX_SCRIPT"
        echo "   已创建临时修复脚本: $FIX_SCRIPT"
        echo ""
        echo "   使用方法:"
        echo "   1. 直接使用: $FIX_SCRIPT"
        echo "   2. 在 make 命令中: make ... GDB=$FIX_SCRIPT"
        echo "   3. 或设置别名: alias riscv-gdb='$FIX_SCRIPT'"
    else
        echo "   ✅ GDB 依赖检查通过"
        echo "   GDB 版本信息:"
        "$GDB_PATH" --version 2>/dev/null | head -1 || echo "   无法获取版本信息"
    fi
fi

echo ""
echo "8. 测试编译:"
cat > /tmp/test_riscv_$$.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello RISC-V!\n");
    return 0;
}
EOF

if riscv64-unknown-elf-gcc -o /tmp/test_riscv_$$.elf /tmp/test_riscv_$$.c 2>/dev/null; then
    echo "   ✅ 测试编译成功"
    echo "   生成文件信息:"
    file /tmp/test_riscv_$$.elf
    # 清理测试文件
    rm -f /tmp/test_riscv_$$.c /tmp/test_riscv_$$.elf
else
    echo "   ❌ 测试编译失败"
    echo "   错误信息:"
    riscv64-unknown-elf-gcc -o /tmp/test_riscv_$$.elf /tmp/test_riscv_$$.c 2>&1 | head -5
    rm -f /tmp/test_riscv_$$.c /tmp/test_riscv_$$.elf
fi