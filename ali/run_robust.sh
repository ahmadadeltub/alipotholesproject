#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Run GUI Robust on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > run_robust.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

# Setup environment
send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"

# Run with unbuffered output to log
send "python3 -u potholes.py > gui.log 2>&1 &\r"
expect "$PI_USER@"

# Monitor log
send "tail -f gui.log\r"
# Expect some known output to confirm start
expect {
    "Loading model..." { puts "\n--- Model Loading ---" }
    "Model loaded." { puts "\n--- Model Loaded ---" }
    "Tkinter" { puts "\n--- Tkinter Error? ---" }
    "Traceback" { puts "\n--- CRASH ---"; exit 1 }
}
interact
EOF
chmod +x run_robust.exp
./run_robust.exp
rm run_robust.exp
