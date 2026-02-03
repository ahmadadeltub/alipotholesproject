#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

cat <<EOF > check_install.exp
#!/usr/bin/expect -f
set timeout 10
spawn ssh $SSH_OPTS $PI_USER@$PI_IP "python3 -c \"import ultralytics; print('INSTALLED_OK')\""
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x check_install.exp
./check_install.exp
rm check_install.exp
