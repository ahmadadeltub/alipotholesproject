#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Deploying Real-Time Location to Pi"
echo "=========================================="

# 1. Transfer Code
echo "[1/3] Uploading potholes.py..."
cat <<EOF > upload_loc.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS potholes.py $PI_USER@$PI_IP:/home/pi
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x upload_loc.exp
./upload_loc.exp
rm upload_loc.exp

# 2. Install Dependency & Restart
echo "[2/3] Installing requests & Restarting..."
cat <<EOF > restart_loc.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pip3 install requests --break-system-packages\r"
expect "$PI_USER@"

send "pkill -f potholes.py\r"
send "export DISPLAY=:0\r"
send "export XAUTHORITY=/home/pi/.Xauthority\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd /home/pi\r"

# Restart Main App
send "python3 potholes.py >> app.log 2>&1 &\r"

expect "$PI_USER@"
send "echo '--- Location Update Live ---'\r"
interact
EOF
chmod +x restart_loc.exp
./restart_loc.exp
rm restart_loc.exp
