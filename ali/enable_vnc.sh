#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Enabling VNC on Pi ($PI_IP)"
echo "=========================================="

cat <<EOF > enable_vnc.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "echo 'Enabling VNC Server...'\r"
# Enable VNC via raspi-config (0 = enable)
send "sudo raspi-config nonint do_vnc 0\r"
expect "$PI_USER@"

# Check status
send "systemctl status vncserver-x11-serviced.service || systemctl status wayvnc\r"
expect "$PI_USER@"

send "echo 'VNC Enabled. Connect using RealVNC Viewer.'\r"
interact
EOF
chmod +x enable_vnc.exp
./enable_vnc.exp
rm enable_vnc.exp
