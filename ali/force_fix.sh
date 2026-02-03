#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Force Fixing Data on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > force_fix.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "cd /home/pi\r"

# 1. Force Create potholes.json - Escape brackets for Tcl
send "echo '\[\{\"id\": \"Loc1\", \"lat\": 25.2854, \"lon\": 51.5360, \"image\": \"pothole1.png\", \"date\": \"Fixed\"\}\]' > potholes.json\r"
expect "$PI_USER@"

# 2. Check Python syntax
send "python3 -m py_compile potholes.py\r"
expect {
    "Error" { puts "SYNTAX ERROR IN POTHOLES.PY" }
    "$PI_USER@"
}

# 3. Restart
send "pkill -f potholes.py\r"
send "pkill -f server.py\r"
send "export DISPLAY=:0\r"
# Ensure X authority is right for root/sudo if needed, but running as pi should be fine if logged in desktop
send "export XAUTHORITY=/home/pi/.Xauthority\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"

# Run and capture output to separate files
send "python3 server.py > web_debug.log 2>&1 &\r"
send "python3 potholes.py > app_debug.log 2>&1 &\r"

expect "$PI_USER@"
send "echo '--- SERVERS RESTARTED ---'\r"
interact
EOF
chmod +x force_fix.exp
./force_fix.exp
rm force_fix.exp
