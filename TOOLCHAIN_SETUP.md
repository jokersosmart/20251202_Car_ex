# Tool Chain Setup for Power Management Safety Project

## Overview
This guide provides setup instructions for all development tools required for the ISO 26262 ASIL-B power management safety project.

## Prerequisites
- Windows 10+ or Linux (Ubuntu 20.04+)
- Administrator/root access
- Internet connection

## Tool Installation

### 1. Python 3.8+ (Required for firmware testing and analysis)

**Windows:**
```powershell
# Download from https://www.python.org/downloads/
# Or use package manager:
choco install python --version=3.11
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install python3.11 python3-pip python3-venv
```

### 2. GCC/ARM Toolchain (Required for firmware compilation)

**Windows:**
```powershell
# Download ARM GNU Embedded Toolchain
# https://developer.arm.com/tools-and-software/open-source-software/gnu-toolchain/gnu-rm/downloads

# Extract to: C:\tools\gcc-arm-embedded
# Add to PATH

# Verify:
arm-none-eabi-gcc --version
```

**Linux:**
```bash
sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi gdb-arm-none-eabi

# Verify:
arm-none-eabi-gcc --version
```

### 3. Verilator (Required for RTL simulation)

**Windows:**
```powershell
# Option 1: Download pre-built binary
# https://www.veripool.org/verilator/

# Option 2: Build from source
git clone https://github.com/verilator/verilator.git
cd verilator
git checkout stable
autoconf
./configure
make
make install

# Verify:
verilator --version
```

**Linux:**
```bash
sudo apt-get install verilator

# Or build from source:
git clone https://github.com/verilator/verilator.git
cd verilator
git checkout stable
autoconf
./configure
make
sudo make install

# Verify:
verilator --version
```

### 4. Python Development Dependencies (Required for testing)

```bash
# Create virtual environment (recommended)
python -m venv venv
source venv/Scripts/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r firmware/requirements.txt

# Verify installations:
pytest --version
coverage --version
lizard --version
cppcheck --version
```

### 5. CMake 3.15+ (Required for build system)

**Windows:**
```powershell
choco install cmake --version=3.24.0
```

**Linux:**
```bash
sudo apt-get install cmake
```

## Verification Checklist

Run the following commands to verify all tools are installed:

```bash
# Python
python --version       # Expected: 3.8+

# C compiler
gcc --version          # Linux/MinGW

# ARM Compiler
arm-none-eabi-gcc --version  # ARM embedded

# RTL simulator
verilator --version    # Expected: v4.200+

# Build system
cmake --version        # Expected: 3.15+

# Python packages (from virtual environment)
pytest --version
coverage --version
lizard --version
cppcheck --version
```

## Development Environment Setup

### 1. Create Python Virtual Environment
```bash
cd c:\Users\user\Desktop\ISO_del
python -m venv venv
source venv/Scripts/activate  # Windows: venv\Scripts\activate
```

### 2. Install All Dependencies
```bash
pip install --upgrade pip setuptools wheel
pip install -r firmware/requirements.txt
```

### 3. Configure IDE (VS Code)

Create `.vscode/settings.json`:
```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "C_Cpp.default.compilerPath": "arm-none-eabi-gcc",
  "C_Cpp.default.cStandard": "c11",
  "[python]": {
    "editor.defaultFormatter": "ms-python.python",
    "editor.formatOnSave": true
  }
}
```

## Build Process

### Compile Firmware
```bash
cd firmware
mkdir build
cd build
cmake ..
make
```

### Run Firmware Tests
```bash
cd firmware/tests
pytest -v --cov=../src
```

### Simulate RTL
```bash
cd rtl
verilator -f verilator.cfg --cc --exe power_monitor_tb.cpp power_monitor.v
make -C obj_dir -f Vpower_monitor.mk
obj_dir/Vpower_monitor
```

### Static Analysis
```bash
# C code analysis
cppcheck firmware/src --suppress=missingIncludeSystem

# Python code analysis
lizard firmware/src
```

## Troubleshooting

### Verilator not found
- Ensure Verilator is installed in system PATH
- On Windows, add `C:\tools\verilator\bin` to PATH environment variable
- Verify: `which verilator` (Linux) or `where verilator` (Windows)

### ARM compiler not found
- Verify ARM toolchain installation location
- Add to PATH: `C:\tools\gcc-arm-embedded\bin` (Windows)
- Linux: May need `sudo update-alternatives --install /usr/bin/arm-gcc arm-gcc /opt/gcc-arm/bin/arm-none-eabi-gcc 100`

### Python packages fail to install
- Ensure you're in the virtual environment
- Run: `pip install --upgrade pip`
- Clear cache: `pip cache purge`
- Retry: `pip install -r firmware/requirements.txt`

### CMake build fails
- Ensure CMake version ≥ 3.15: `cmake --version`
- Check compiler PATH
- Remove build directory and try again

## References
- [Verilator Documentation](https://verilator.org/guide/latest/)
- [ARM Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/gnu-toolchain/gnu-rm/)
- [Python Testing Framework](https://docs.pytest.org/)
- [Cppcheck Manual](http://cppcheck.sourceforge.net/)
