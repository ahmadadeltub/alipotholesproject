#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Configuring Autostart on Pi ($PI_IP)"
echo "=========================================="

# 1. Transfer Config Files
echo "[1/3] Transferring Scripts..."
cat <<EOF > transfer_config.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS start_rover.sh rover.desktop $PI_USER@$PI_IP:/home/pi
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x transfer_config.exp
./transfer_config.exp
rm transfer_config.exp

# 2. Setup on Pi
echo "[2/3] Installing .desktop entry..."
cat <<EOF > install_autostart.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

# Make script executable
send "chmod +x /home/pi/start_rover.sh\r"

# Create autostart directory if not exists
send "mkdir -p /home/pi/.config/autostart\r"

# Move desktop file
send "mv /home/pi/rover.desktop /home/pi/.config/autostart/rover.desktop\r"

expect "$PI_USER@"
send "echo '--- Autostart Configured Successfully ---'\r"
interact
EOF
chmod +x install_autostart.exp
./install_autostart.exp
rm install_autostart.exp

echo "Done! The app will now start automatically when the Pi boots."
