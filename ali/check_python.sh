#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > check_python.exp
#!/usr/bin/expect -f
set timeout 10
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}
send "python3 --version\r"
expect "$PI_USER@"
send "pip3 --version\r"
expect "$PI_USER@"
send "ls -d /home/pi/.local/lib/python*\r"
expect "$PI_USER@"
EOF
chmod +x check_python.exp
./check_python.exp
rm check_python.exp
