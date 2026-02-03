#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
LOCAL_FILES="potholes.py pothole1.png pothole2.png pothole3.png"

echo "=========================================="
echo "Deploying Modern GUI to Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Files
echo "[1/3] Transferring code and images..."
cat <<EOF > transfer_modern.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_modern.exp
./transfer_modern.exp
rm transfer_modern.exp

# 2. Install Dependencies & Run
echo "[2/3] Installing tkintermapview and Running..."
cat <<EOF > run_modern.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

# Install map view
send "pip3 install tkintermapview --break-system-packages\r"
expect "$PI_USER@"

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"

# Run unbuffered log
send "python3 -u potholes.py > modern.log 2>&1 &\r"
expect "$PI_USER@"

# Monitor log
send "tail -f modern.log\r"
expect {
    "Model loaded." { puts "\n--- Application Running ---" }
}
interact
EOF
chmod +x run_modern.exp
./run_modern.exp
rm run_modern.exp
