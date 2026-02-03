#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
LOCAL_FILES="potholes.py"

echo "=========================================="
echo "Deploying Final App to Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Code
echo "[1/2] Transferring code..."
cat <<EOF > transfer_final.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_final.exp
./transfer_final.exp
rm transfer_final.exp

# 2. Run
echo "[2/2] Restarting App..."
cat <<EOF > run_final.exp
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
send "python3 -u potholes.py > final.log 2>&1 &\r"
expect "$PI_USER@"

# Monitor log
send "tail -f final.log\r"
expect {
    "Model loaded." { puts "\n--- Final App Running ---" }
}
interact
EOF
chmod +x run_final.exp
./run_final.exp
rm run_final.exp
