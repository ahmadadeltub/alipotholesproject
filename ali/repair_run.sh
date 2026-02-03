#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Repair & Run on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > repair_run.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

# Explicitly repair with non-interactive frontend
send "sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

# Install
send "sudo apt-get install -y --fix-broken python3-tk python3-pil.imagetk\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    # Start app immediately if install works
    "$PI_USER@"
}

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

puts "\n--- GUI Application Starting ---"
interact
EOF
chmod +x repair_run.exp
./repair_run.exp
rm repair_run.exp
