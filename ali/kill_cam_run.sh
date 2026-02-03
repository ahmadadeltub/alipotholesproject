#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Kill Camera & Run on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > kill_cam_run.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "echo 'Killing previous instances...'\r"
send "pkill -9 -f potholes.py\r"
expect "$PI_USER@"
send "pkill -9 -f python\r"
expect "$PI_USER@"
send "pkill -9 -f python3\r"
expect "$PI_USER@"

# Kill common camera apps
send "pkill -9 -f rpicam\r"
expect "$PI_USER@"
send "pkill -9 -f libcamera\r"
expect "$PI_USER@"

# Check who is holding the device
send "fuser -v /dev/media*\r"
expect "$PI_USER@"
# Kill them
send "sudo fuser -k -9 /dev/media*\r"
expect "$PI_USER@"

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

puts "\n--- GUI Application Starting ---"
interact
EOF
chmod +x kill_cam_run.exp
./kill_cam_run.exp
rm kill_cam_run.exp
