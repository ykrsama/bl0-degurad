#!/bin/bash
RAW_ARCH=$(uname -m)
case ${RAW_ARCH} in
    x86_64)  ARCH="x64" ;;
    aarch64) ARCH="ARM64" ;;
    *)       ARCH=${RAW_ARCH} ;;
esac

echo "Building setname.so (static)"
g++ -fPIC -shared -static-libstdc++ -static-libgcc -o setname.so setname.cpp

echo "Convertint setname.so into C++ hearder payload"
xxd -i setname.so > setname_payload.h

echo "Building wrap (static)"
g++ -static -o wrap wrap.cpp

echo "[Cleanup]"
rm setname.so setname_payload.h

echo "==================================="
echo "Done."
echo "You can run wrap on any ${ARCH} Linux"
echo "Usage: ./wrap <command> [args...]"
echo "Example: ./wrap python3 -c 'print(\"Hello World!\")'"
