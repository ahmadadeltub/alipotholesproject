#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > check_process.exp
#!/usr/bin/expect -f
set timeout 20
spawn ssh $SSH_OPTS $PI_USER@$PI_IP "ps aux | grep pip"
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x check_process.exp
./check_process.exp
rm check_process.exp
