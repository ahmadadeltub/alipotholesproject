#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo " performing CLEAN RESTART on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > clean_restart.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "echo '--- Stopping Services ---'\r"
send "pkill -f potholes.py\r"
send "pkill -f server.py\r"
send "sleep 2\r"

send "echo '--- Resetting Environment ---'\r"
send "sudo chmod 666 /dev/ttyACM2\r"
send "rm -f app.log web.log\r"
send "export DISPLAY=:0\r"
send "export XAUTHORITY=/home/pi/.Xauthority\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd /home/pi\r"

send "echo '--- Starting Services ---'\r"
send "python3 -u server.py > web.log 2>&1 &\r"
send "python3 -u potholes.py > app.log 2>&1 &\r"
send "sleep 5\r"

send "echo '--- Verifying Status ---'\r"
send "pgrep -af python3\r"
expect "$PI_USER@"

send "echo '--- RESTART COMPLETE ---'\r"
interact
EOF
chmod +x clean_restart.exp
./clean_restart.exp
rm clean_restart.exp
