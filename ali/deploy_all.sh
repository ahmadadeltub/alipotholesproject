#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
LOCAL_FILES="potholes.py server.py rover_icon.png pothole1.png pothole2.png pothole3.png pothole4.png pothole5.png pothole6.png templates rover_launcher.sh rover.desktop"
REMOTE_DIR="/home/pi"

echo "=========================================="
echo "Full System Deployment to Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer All Files (Code + Web Templates)
echo "[1/3] Syncing Code & Web Assets..."
cat <<EOF > transfer_all.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp -r $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_all.exp
./transfer_all.exp
rm transfer_all.exp

# 2. Install Dependencies & Restart Services
echo "[2/3] Updating Environment & Restarting..."
cat <<EOF > restart_all.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

# Install ALL dependencies
send "pip3 install flask requests pyserial pynmea2 --break-system-packages\r"
expect "$PI_USER@"

# Kill old processes
send "pkill -f potholes.py\r"
send "pkill -f server.py\r"
send "sleep 2\r"

# Fix GPS Permissions
send "sudo chmod 666 /dev/ttyACM2\r"
expect "$PI_USER@"

# Setup Display environment
send "export DISPLAY=:0\r"
send "export XAUTHORITY=/home/pi/.Xauthority\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"

# 1. Start Web Server
send "python3 -u server.py > web.log 2>&1 &\r"

# 2. Start Main GUI App
send "python3 -u potholes.py > app.log 2>&1 &\r"

expect "$PI_USER@"
send "chmod +x rover_launcher.sh\\r"
send "mkdir -p /home/pi/.config/autostart\\r"
send "mv rover.desktop /home/pi/.config/autostart/\\r"
send "echo '--- Starting Services ---\r'"
send "echo 'GPS: Active | Web: Active | App: Active'\r"
interact
EOF
chmod +x restart_all.exp
./restart_all.exp
rm restart_all.exp
