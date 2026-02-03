#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > run_only.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "export DISPLAY=:0\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

expect {
    "Running real-time pothole detection..." { 
        puts "\n--- SUCCESS: App started ---"
        # We don't want to kill it immediately, let it run.
        # But run_command interact will hang.
        # So we just exit expect, which kills SSH, which kills app?
        # Usually yes.
        # To keep it running, we might need nohup, but user wants to "run code" and probably see it?
        # The user has the device.
        # I'll leave it running for 10 seconds then exit.
        sleep 10
    }
    timeout { puts "\n--- TIMEOUT waiting for start message ---"; exit 1 }
}
EOF
chmod +x run_only.exp
./run_only.exp
rm run_only.exp
