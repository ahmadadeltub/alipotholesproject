#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Sanity Check on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > sanity.exp
#!/usr/bin/expect -f
set timeout 20
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "echo '--- Simple Print ---'\r"
send "python3 -c \"print('Hello World')\"\r"
expect "$PI_USER@"

send "echo '--- Tkinter Import ---'\r"
send "python3 -c \"import tkinter; print('Tkinter Imported')\"\r"
expect "$PI_USER@"

send "echo '--- PIL Import ---'\r"
send "python3 -c \"from PIL import Image, ImageTk; print('PIL Imported')\"\r"
expect "$PI_USER@"
EOF
chmod +x sanity.exp
./sanity.exp
rm sanity.exp
