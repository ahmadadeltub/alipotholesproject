#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
# Files (images are already there, just update code)
LOCAL_FILES="potholes.py"

echo "=========================================="
echo "Updating Map Controls on Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Code
echo "[1/2] Transferring updated code..."
cat <<EOF > transfer_controls.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_controls.exp
./transfer_controls.exp
rm transfer_controls.exp

# 2. Run
echo "[2/2] Restarting App..."
cat <<EOF > run_controls.exp
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
send "python3 -u potholes.py > controls.log 2>&1 &\r"
expect "$PI_USER@"

# Monitor log
send "tail -f controls.log\r"
expect {
    "Model loaded." { puts "\n--- Map Controls Active ---" }
}
interact
EOF
chmod +x run_controls.exp
./run_controls.exp
rm run_controls.exp
