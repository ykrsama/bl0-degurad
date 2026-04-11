#!/bin/bash
set -e

echo "[1/3] 正在编译独立的 setname.so (剥离 C++ 动态库依赖)..."
# 将 C++ 运行时静态打入，确保 .so 不依赖 CVMFS 下的高版本库
g++ -fPIC -shared -static-libstdc++ -static-libgcc -o setname.so setname.cpp

echo "[2/3] 正在将 setname.so 转换为 C++ 头文件 payload..."
# xxd 会根据文件名生成 setname_so 数组和 setname_so_len 长度变量
xxd -i setname.so > setname_payload.h

echo "[3/3] 正在编译完全静态的单文件启动器 wrap..."
# -static 保证最终二进制没有任何动态依赖 (not a dynamic executable)
g++ -static -o wrap wrap.cpp

echo "[Cleanup] 清理临时中间文件..."
rm setname.so setname_payload.h

echo "==================================="
echo "✅ 编译完成！"
echo "现在你只需要 'wrap' 这一个文件，它可以脱离环境在任意 x86_64 Linux 机器上独立运行。"
