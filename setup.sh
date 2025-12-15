# Update system
sudo apt-get update
sudo apt-get upgrade

# Install Edge TPU runtime
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update

# Install the runtime (standard version - safer for beginners)
sudo apt-get install libedgetpu1-std

# Install Python API
sudo apt-get install python3-pycoral

# Install OpenCV and other dependencies
sudo apt-get install python3-opencv
pip3 install pillow numpy
