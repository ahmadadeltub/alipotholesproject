#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
# Include all 6 images
LOCAL_FILES="potholes.py pothole1.png pothole2.png pothole3.png pothole4.png pothole5.png pothole6.png"

echo "=========================================="
echo "Updating Map Locations on Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Files
echo "[1/2] Transferring code and NEW images..."
cat <<EOF > transfer_update.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_update.exp
./transfer_update.exp
rm transfer_update.exp

# 2. Run
echo "[2/2] Restarting App..."
cat <<EOF > run_update.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"

# Run unbuffered log
send "python3 -u potholes.py > modern_v2.log 2>&1 &\r"
expect "$PI_USER@"

# Monitor log
send "tail -f modern_v2.log\r"
expect {
    "Model loaded." { puts "\n--- Application Updated & Running ---" }
}
interact
EOF
chmod +x run_update.exp
./run_update.exp
rm run_update.exp
