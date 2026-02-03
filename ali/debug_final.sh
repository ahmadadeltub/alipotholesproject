#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > debug_final.exp
#!/usr/bin/expect -f
set timeout 10
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}
send "ls -F /home/pi/.local/lib/python3.13/site-packages/\r"
expect "$PI_USER@"
send "python3 -c 'import site; print(site.getsitepackages()); print(site.getusersitepackages())'\r"
expect "$PI_USER@"
EOF
chmod +x debug_final.exp
./debug_final.exp
rm debug_final.exp
