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

echo -e "${BLUE}Building setname.so (static)...${NC}"
g++ -fPIC -shared -static-libstdc++ -static-libgcc -o setname.so setname.cpp

echo -e "${BLUE}Converting setname.so into C++ header payload...${NC}"
xxd -i setname.so > setname_payload.h

echo -e "${BLUE}Building wrap (static)...${NC}"
g++ -static -o wrap wrap.cpp

echo -e "${BLUE}[Cleanup]${NC}"
rm setname.so setname_payload.h

echo -e "${GREEN}Done.${NC}"
echo -e "\nYou can run wrap on any ${ARCH} Linux."
echo -e "${YELLOW}Usage:${NC}"
echo -e "./wrap <command> [args...]"
echo -e "${YELLOW}Example:${NC}"
echo -e "./wrap python3 -c 'print(\"Cluster Guard Bypassed!\")'"
