#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Nuclear Unlock & Install on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > nuclear_unlock.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

# Kill everything related to packages
send "sudo killall -9 dpkg apt apt-get packagekitd unattended-upgrade\r"
expect "$PI_USER@"
send "sudo rm /var/lib/dpkg/lock*\r"
expect "$PI_USER@"
send "sudo rm /var/lib/apt/lists/lock\r"
expect "$PI_USER@"
send "sudo rm /var/cache/apt/archives/lock\r"
expect "$PI_USER@"

# Repair
send "sudo dpkg --configure -a\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "echo 'Installing Tkinter support...'\r"
send "sudo apt-get update && sudo apt-get install -y --fix-broken python3-tk python3-pil.imagetk\r"
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
chmod +x nuclear_unlock.exp
./nuclear_unlock.exp
rm nuclear_unlock.exp
