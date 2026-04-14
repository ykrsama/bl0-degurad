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
./wrap <command> [args...]
```

Example:

```bash
./wrap python3 -c 'print("Cluster Guard Bypassed!")'
```
