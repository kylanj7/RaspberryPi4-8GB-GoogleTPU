#!/bin/bash
# Coral TPU Setup Script for Raspberry Pi
# Tested on Raspberry Pi 4 with Debian Trixie

set -e  # Exit on any error

echo "# ----------------------------------------"
echo "Coral TPU Installation Script"
echo "# ----------------------------------------"

# Update system
echo "Updating system packages..."
sudo apt-get update

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# Install pyenv if not already installed
if [ ! -d "$HOME/.pyenv" ]; then
    echo "Installing pyenv..."
    curl https://pyenv.run | bash
    
    # Add pyenv to bashrc if not already there
    if ! grep -q "pyenv init" ~/.bashrc; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    fi
    
    # Load pyenv for current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Install Python 3.9 via pyenv
echo "Installing Python 3.9.19..."
pyenv install -s 3.9.19  # -s skips if already installed

# Install Coral Edge TPU runtime
echo "Installing Coral Edge TPU runtime..."
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/coral-edgetpu-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/coral-edgetpu-archive-keyring.gpg] https://packages.cloud.google.com/apt coral-edgetpu-stable main" | \
    sudo tee /etc/apt/sources.list.d/coral-edgetpu.list

sudo apt-get update
sudo apt-get install -y libedgetpu1-std

# Create project directory
PROJECT_DIR="$HOME/Desktop/GoogleTPU"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Set Python 3.9 for this project
pyenv local 3.9.19

# Create virtual environment
echo "Creating virtual environment..."
python -m venv coral_env

# Activate virtual environment
source coral_env/bin/activate

# Upgrade pip
echo "Installing Python packages..."
pip install --upgrade pip

# Install packages in correct order
pip install "numpy<2"  # Must be <2 for pycoral compatibility
pip install pillow
pip install opencv-python

# Install TFLite runtime
pip install --extra-index-url https://google-coral.github.io/py-repo/ tflite-runtime

# Install PyCoral
pip install --extra-index-url https://google-coral.github.io/py-repo/ pycoral

# Create test script
cat > test_coral.py << 'EOF'
#!/usr/bin/env python3
import sys
print(f"Python: {sys.version}\n")

results = {}

# Test TFLite
try:
    import tflite_runtime.interpreter as tflite
    results['tflite-runtime'] = '✓'
except Exception as e:
    results['tflite-runtime'] = f'✗ {str(e)[:50]}'

# Test PyCoral
try:
    from pycoral.utils import edgetpu
    from pycoral.adapters import common, classify
    results['pycoral'] = '✓'
except Exception as e:
    results['pycoral'] = f'✗ {str(e)[:50]}'

# Test libedgetpu
try:
    import ctypes
    ctypes.CDLL('libedgetpu.so.1')
    results['libedgetpu'] = '✓'
except Exception as e:
    results['libedgetpu'] = f'✗ {str(e)[:50]}'

# Test TPU detection
try:
    from pycoral.utils import edgetpu
    devices = edgetpu.list_edge_tpus()
    results['TPU devices'] = f'✓ Found {len(devices)}'
except Exception as e:
    results['TPU devices'] = f'✗ {str(e)[:50]}'

# Other packages
for pkg in ['numpy', 'PIL', 'cv2']:
    try:
        __import__(pkg)
        results[pkg] = '✓'
    except:
        results[pkg] = '✗'

print("="*50)
for k, v in results.items():
    print(f"{k:20s}: {v}")
print("="*50)

all_ok = all('✓' in str(v) for v in results.values())
print("\n🎉 READY FOR COMPUTER VISION!" if all_ok else "\n⚠️ Issues found")
EOF

chmod +x test_coral.py

# Save requirements
pip freeze > requirements.txt

# Test installation
echo ""
echo "# ----------------------------------------"
echo "Testing installation..."
echo "# ----------------------------------------"
python test_coral.py

echo ""
echo "# ----------------------------------------"
echo "Installation complete!"
echo "# ----------------------------------------"
echo ""
echo "To activate the environment in future sessions:"
echo "  cd $PROJECT_DIR"
echo "  source coral_env/bin/activate"
echo ""
echo "Your requirements have been saved to requirements.txt"
