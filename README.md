# Bypass cpu time wall on bl-0 login node!

The binary is statically compiled, can be used in any Linux including container.

Build:

```bash
source /cvmfs/sft.cern.ch/lcg/views/LCG_102/x86_64-centos7-gcc11-opt/setup.sh
# or any other environment with gcc version > 8
. compile.sh
export PATH=/to/this/path:$PATH
```

Usage:

```bash
./wrap <absolute_binary_path> [args...]
```

Example:

```bash
./wrap "$(command -v python3)" -c 'print("Hello World!")'
```
