#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Force Unlock & Install on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > force_install.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

# Force kill process holding lock
send "sudo fuser -viki -TERM /var/lib/dpkg/lock-frontend\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "Kill process" { send "y\r"; exp_continue }
    "$PI_USER@"
}

# Repair just in case
send "sudo dpkg --configure -a\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "echo 'Installing Tkinter support...'\r"
send "sudo apt-get install -y python3-tk python3-pil.imagetk\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

puts "\n--- GUI Application Starting ---"
interact
EOF
chmod +x force_install.exp
./force_install.exp
rm force_install.exp
