#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Deploying GPS Support to Pi"
echo "=========================================="

# 1. Transfer Code
echo "[1/3] Uploading potholes.py..."
cat <<EOF > upload_gps.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS potholes.py $PI_USER@$PI_IP:/home/pi
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x upload_gps.exp
./upload_gps.exp
rm upload_gps.exp

# 2. Install Dependencies & Restart
echo "[2/3] Installing pyserial, pynmea2..."
cat <<EOF > restart_gps.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pip3 install pyserial pynmea2 requests flask --break-system-packages\r"
expect "$PI_USER@"

# Add permission to access serial port if needed
# send "sudo usermod -a -G dialout pi\r"
# expect "$PI_USER@"

send "sudo chmod 666 /dev/ttyACM0\r"
expect "$PI_USER@"

send "pkill -f potholes.py\r"
send "pkill -f server.py\r"
send "export DISPLAY=:0\r"
send "export XAUTHORITY=/home/pi/.Xauthority\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd /home/pi\r"

# Restart
send "python3 -u server.py > web.log 2>&1 &\r"
send "python3 -u potholes.py > app.log 2>&1 &\r"

expect "$PI_USER@"
send "echo '--- GPS Update Live ---'\r"
interact
EOF
chmod +x restart_gps.exp
./restart_gps.exp
rm restart_gps.exp
