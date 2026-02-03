#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > debug_path.exp
#!/usr/bin/expect -f
set timeout 10
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}
send "python3 -c 'import sys; print(sys.path)'\r"
expect "$PI_USER@"
send "ls -R /home/pi/.local/lib/python*/site-packages/ultralytics | head -n 5\r"
expect "$PI_USER@"
EOF
chmod +x debug_path.exp
./debug_path.exp
rm debug_path.exp
