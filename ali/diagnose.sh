#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Diagnose on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > diagnose.exp
#!/usr/bin/expect -f
set timeout 10
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"

send "echo '--- Check Tkinter ---'\r"
send "python3 -c \"import tkinter; print('Tkinter OK')\"\r"
expect "$PI_USER@"

send "echo '--- Check PIL ---'\r"
send "python3 -c \"from PIL import Image, ImageTk; print('PIL OK')\"\r"
expect "$PI_USER@"

send "echo '--- Check Picamera2 ---'\r"
send "python3 -c \"from picamera2 import Picamera2; print('Picamera2 OK')\"\r"
expect "$PI_USER@"

send "echo '--- Run App & Capture Output ---'\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py > run.log 2>&1\r"
# Wait a bit
sleep 5
# Interrupt if stuck/running (we want to see log)
send "\003" 
expect "$PI_USER@"
send "cat run.log\r"
expect "$PI_USER@"

EOF
chmod +x diagnose.exp
./diagnose.exp
rm diagnose.exp
