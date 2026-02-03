#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
LOCAL_FILES="potholes.py server.py templates"

echo "=========================================="
echo "Deploying Web Dashboard to Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Code
echo "[1/3] Transferring code & templates..."
# We use -r for recursive template dir
cat <<EOF > transfer_web.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp -r $SSH_OPTS $LOCAL_FILES $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_web.exp
./transfer_web.exp
rm transfer_web.exp

# 2. Run Main App + Web Server
echo "[2/3] Installing Flask..."
cat <<EOF > install_flask.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}
send "pip3 install flask requests --break-system-packages\r"
expect "$PI_USER@"
interact
EOF
chmod +x install_flask.exp
./install_flask.exp
rm install_flask.exp

echo "[3/3] Restarting Services..."
cat <<EOF > run_web_services.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
send "pkill -f server.py\r"
sleep 1

send "export DISPLAY=:0\r"
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"

# 1. Start Main App
send "python3 -u potholes.py > app.log 2>&1 &\r"

# 2. Start Web Server
send "python3 -u server.py > web.log 2>&1 &\r"
expect "$PI_USER@"

send "echo '--- Web Dashboard running on Port 5000 ---'\r"
interact
EOF
chmod +x run_web_services.exp
./run_web_services.exp
rm run_web_services.exp
