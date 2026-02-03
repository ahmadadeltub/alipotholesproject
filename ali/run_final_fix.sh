#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > run_final_fix.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

send "export DISPLAY=:0\r"
# Use \\\$ to produce \$ in file, which Tcl interprets as literal $
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

expect {
    "Running real-time pothole detection..." { 
        puts "\n--- SUCCESS: App started ---"
        sleep 15
    }
    timeout { puts "\n--- TIMEOUT waiting for start message ---"; exit 1 }
}
EOF
chmod +x run_final_fix.exp
./run_final_fix.exp
rm run_final_fix.exp
