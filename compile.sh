#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RAW_ARCH=$(uname -m)
case ${RAW_ARCH} in
    x86_64)  ARCH="${RED}x64${NC}" ;;
    aarch64) ARCH="${RED}ARM64${NC}" ;;
    *)       ARCH="${RED}${RAW_ARCH}${NC}" ;;
esac

# --- GCC VERSION CHECK ---
if ! command -v g++ &> /dev/null; then
    echo -e "${RED}ERROR: g++ not found. Please install GCC.${NC}"
    exit 1
fi

GCC_VERSION=$(g++ -dumpversion | cut -d. -f1)

if [ "$GCC_VERSION" -le 8 ]; then
    echo -e "${RED}ERROR: g++ version = $GCC_VERSION.${NC}"
    echo -e "${YELLOW}This program needs g++ version > 8 to compile.${NC}"
    exit 1
fi

# --- COMPILE ---

echo -e "${BLUE}Building setname.so (static)...${NC}"
g++ -fPIC -shared -static-libstdc++ -static-libgcc -o setname.so setname.cpp

echo -e "${BLUE}Converting setname.so into C++ header payload...${NC}"
xxd -i setname.so > setname_payload.h

mkdir -p bin

echo -e "${BLUE}Building wrap (static)...${NC}"
g++ -static -o bin/wrap wrap.cpp

echo -e "${BLUE}[Cleanup]${NC}"
rm setname.so setname_payload.h

echo -e "${GREEN}Done.${NC}"
echo -e "\nYou can run wrap on any ${ARCH} Linux."

# --- AUTO-UPDATE .bashrc ---
BASHRC_FILE="$HOME/.bashrc"
EXPORT_LINE="export PATH=\"${PWD}/bin:\$PATH\""

# 使用 grep -Fxq 进行整行严格匹配，且静默输出
if grep -Fxq "$EXPORT_LINE" "$BASHRC_FILE"; then
    echo -e "${GREEN}✔ PATH is already configured in ~/.bashrc.${NC}"
else
    echo -e "${YELLOW}Adding bin/ directory to ~/.bashrc PATH...${NC}"
    # 追加前先加个空行，防止跟文件末尾的内容粘连
    echo "" >> "$BASHRC_FILE"
    echo "# Added by wrap build script" >> "$BASHRC_FILE"
    echo "$EXPORT_LINE" >> "$BASHRC_FILE"
    echo -e "${GREEN}✔ Successfully added to ~/.bashrc.${NC}"
    echo -e "${YELLOW}Run 'source ~/.bashrc' or restart your terminal to apply the changes.${NC}"
fi

echo -e "\n${YELLOW}Usage:${NC}"
echo -e "wrap <command> [args...]"
echo -e "${YELLOW}Example:${NC}"
echo -e "wrap python3 -c 'print(\"Cluster Guard Bypassed!\")'"
