#!/bin/bash

# Coral TPU Setup Script for Raspberry Pi 4 8GB
# Tested on Debian Trixie 13.2

set -e  # Exit on any error

echo "=========================================="
echo "Coral TPU Installation Script"
echo "=========================================="

# Update system
echo "Updating system packages..."
sudo apt-get update

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

# Create project directory
PROJECT_DIR="$HOME/RPi4-8GB-CoralTPU"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Set Python 3.9 for this project
pyenv local 3.9.19

# Create New Virtual Environment
echo "Creating virtual environment..."
python -m venv coral_env

# Activate virtual environment
echo "Activaing the New Python Virtual Environment..." 
source coral_env/bin/activate

# Upgrade pip
echo "Installing Python packages..."
pip install --upgrade pip

# CRITICAL: Install numpy and opencv together with correct versions
# This prevents opencv from upgrading numpy to 2.x
echo "Installing numpy and opencv with pinned versions..."
pip install "numpy<2" "opencv-python<4.10"

# Install the Edge TPU MAX Runtime
echo "Installing EdgeTPU MAX Runtime..."
sudo apt-get install -y libedgetpu1-max

# Add udev rules for TPU access
echo 'SUBSYSTEM=="usb",ATTRS{idVendor}=="1a6e",GROUP="plugdev"' | sudo tee /etc/udev/rules.d/99-edgetpu-accelerator.rules
echo 'SUBSYSTEM=="usb",ATTRS{idVendor}=="18d1",GROUP="plugdev"' | sudo tee -a /etc/udev/rules.d/99-edgetpu-accelerator.rules

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add your user to plugdev group
sudo usermod -a -G plugdev $USER

echo "Installing PyCoral..."
sudo apt-get install python3-pycoral

# CRITICAL: Install numpy and opencv together with correct versions
echo "Installing numpy and opencv with pinned versions..."
pip install "numpy<2" "opencv-python<4.10"

# Install other core packages
pip install pillow

# Install TFLite runtime
echo "Installing TFLite runtime..."
pip install --extra-index-url https://google-coral.github.io/py-repo/ tflite-runtime

# Install PyCoral
echo "Installing PyCoral..."
pip install --extra-index-url https://google-coral.github.io/py-repo/ pycoral

# Numpy Version Error Handling
NUMPY_VERSION=$(python -c "import numpy; print(numpy.__version__)")
echo "NumPy version: $NUMPY_VERSION"
if [[ "$NUMPY_VERSION" == 2.* ]]; then
    echo "ERROR: NumPy was upgraded to 2.x. Fixing..."
    pip install --force-reinstall "numpy<2"
fi

# Download sample models and test data
echo "Downloading sample models..."
mkdir -p models
cd models

wget -q https://github.com/google-coral/test_data/raw/master/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite
wget -q https://github.com/google-coral/test_data/raw/master/coco_labels.txt
wget -q https://github.com/google-coral/test_data/raw/master/grace_hopper.bmp

cd ..

