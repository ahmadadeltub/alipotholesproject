#!/bin/bash

# Configuration
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
LOCAL_FILES="potholes.py best.pt"
REMOTE_DIR="/home/pi"

# SSH Options to ignore host key checking completely
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Starting Deployment to Raspberry Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Files
echo "[1/3] Transferring files ($LOCAL_FILES)..."
# Using expect for SCP
cat <<EOF > transfer_files.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_files.exp
./transfer_files.exp
rm transfer_files.exp

# 2. Install Dependencies
echo "[2/3] Installing dependencies (this may take a few minutes)..."
cat <<EOF > install_deps.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@" { send "echo 'SSH Connected'\r" }
}

expect "$PI_USER@"
send "echo 'Installing dependencies...'\r"
# Install system dependencies for opencv if possible, or pip
send "sudo apt-get update && sudo apt-get install -y python3-opencv libcamera-dev\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

# Install python libs
send "pip3 install ultralytics --break-system-packages\r"
expect "$PI_USER@"

send "exit\r"
expect eof
EOF
chmod +x install_deps.exp
./install_deps.exp
rm install_deps.exp

# 3. Run Application
echo "[3/3] Running Application..."
cat <<EOF > run_app.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "export DISPLAY=:0\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

# We want to see output.
expect "Running real-time pothole detection..."
puts "\n--- Application Started Successfully ---"

# Keep running
interact
EOF
chmod +x run_app.exp
./run_app.exp
