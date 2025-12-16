#!/bin/bash

# Coral TPU Setup Script for Raspberry Pi 4 8GB
# Tested on Debian Trixie 13.2

set -e  # Exit on error

echo "=========================================="
echo "Coral TPU Installation Script (Fixed)"
echo "=========================================="

PROJECT_DIR="$HOME/Coral_TPU"
cd "$PROJECT_DIR"

# 1. Install Python build dependencies FIRST
echo "Installing Python build dependencies..."
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# 2. Install libedgetpu (correct package name)
echo "Installing libedgetpu1-std..."
sudo apt-get install -y libedgetpu1-std

# 3. Setup pyenv if needed
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# 4. Install Python 3.9.19
echo "Installing Python 3.9.19..."
pyenv install -s 3.9.19

# 5. Set local Python version
pyenv local 3.9.19

# 6. Create virtual environment with pyenv Python
echo "Creating virtual environment..."
~/.pyenv/versions/3.9.19/bin/python -m venv coral_env

# 7. Activate and install packages
source coral_env/bin/activate

pip install --upgrade pip

# Install in correct order
pip install "numpy<2" "opencv-python<4.10" pillow

# Install Coral packages
pip install --extra-index-url https://google-coral.github.io/py-repo/ \
    tflite-runtime pycoral

# 8. Setup udev rules
echo "Setting up TPU permissions..."
echo 'SUBSYSTEM=="usb",ATTRS{idVendor}=="1a6e",GROUP="plugdev"' | \
    sudo tee /etc/udev/rules.d/99-edgetpu-accelerator.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -a -G plugdev $USER

# 9. Verify installation
echo "=========================================="
python -c "import numpy; print(f'NumPy: {numpy.__version__}')"
python -c "import cv2; print(f'OpenCV: {cv2.__version__}')"
python -c "import tflite_runtime; print('TFLite: OK')"
python -c "from pycoral.utils import edgetpu; print('PyCoral: OK')"

echo "=========================================="
echo "Installation complete!"
echo "You must LOG OUT and LOG BACK IN for TPU permissions."
echo "=========================================="

# Download sample models and test data
echo "Downloading sample models..."
mkdir -p models
cd models

wget -q https://github.com/google-coral/test_data/raw/master/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite
wget -q https://github.com/google-coral/test_data/raw/master/coco_labels.txt
wget -q https://github.com/google-coral/test_data/raw/master/grace_hopper.bmp

cd ..

# Verify installation
echo "=========================================="
python -c "import numpy; print(f'NumPy: {numpy.__version__}')"
python -c "import cv2; print(f'OpenCV: {cv2.__version__}')"
python -c "import tflite_runtime; print('TFLite: OK')"
python -c "from pycoral.utils import edgetpu; print('PyCoral: OK')"

# Download sample models and test data
echo "Downloading sample models..."
mkdir -p models
wget -q -P models https://github.com/google-coral/test_data/raw/master/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite
wget -q -P models https://github.com/google-coral/test_data/raw/master/coco_labels.txt
wget -q -P models https://github.com/google-coral/test_data/raw/master/grace_hopper.bmp

# Create test script
cat > test_coral.py << 'EOF'
#!/usr/bin/env python3
import sys

def check_component(name, import_func):
    try:
        import_func()
        print(f"✓ {name}")
        return True
    except Exception as e:
        print(f"✗ {name}: {e}")
        return False

checks = [
    ("NumPy", lambda: __import__('numpy')),
    ("OpenCV", lambda: __import__('cv2')),
    ("Pillow", lambda: __import__('PIL')),
    ("TFLite Runtime", lambda: __import__('tflite_runtime')),
    ("PyCoral", lambda: __import__('pycoral')),
]

print("Component Check:")
all_passed = all(check_component(name, func) for name, func in checks)

# Check TPU
try:
    from pycoral.utils import edgetpu
    devices = edgetpu.list_edge_tpus()
    if devices:
        print(f"✓ Coral TPU detected: {devices[0]}")
    else:
        print("✗ Coral TPU not detected (check power/USB/permissions)")
except Exception as e:
    print(f"✗ TPU check failed: {e}")
    all_passed = False

sys.exit(0 if all_passed else 1)
EOF

chmod +x test_coral.py

echo "=========================================="
echo "Installation complete!"
echo "You must LOG OUT and LOG BACK IN for TPU permissions."
echo ""
echo "Then run: source ~/Coral_TPU/coral_env/bin/activate"
echo "          python test_coral.py"
echo "=========================================="
