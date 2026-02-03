#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > debug_pip.exp
#!/usr/bin/expect -f
set timeout 10
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}
send "pip3 list | grep ultralytics\r"
expect "$PI_USER@"
send "pip3 show ultralytics\r"
expect "$PI_USER@"
EOF
chmod +x debug_pip.exp
./debug_pip.exp
rm debug_pip.exp
