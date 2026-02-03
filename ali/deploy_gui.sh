#!/bin/bash
PI_IP="192.168.1.2"
PI_USER="pi"
PI_PASS="pi"
REMOTE_DIR="/home/pi"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "=========================================="
echo "Updating GUI on Raspberry Pi ($PI_IP)"
echo "=========================================="

# 1. Update File
echo "[1/2] Updating potholes.py..."
cat <<EOF > update_file.exp
#!/usr/bin/expect -f
set timeout -1
spawn scp $SSH_OPTS potholes.py $PI_USER@$PI_IP:$REMOTE_DIR
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    eof
}
EOF
chmod +x update_file.exp
./update_file.exp
rm update_file.exp

# 2. Install Tkinter/Pillow & Run
echo "[2/2] Installing GUI libs and Running..."
cat <<EOF > run_gui.exp
#!/usr/bin/expect -f
set timeout -1
spawn ssh $SSH_OPTS $PI_USER@$PI_IP
expect {
    "password:" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "pkill -f potholes.py\r"
expect "$PI_USER@"

send "echo 'Installing Tkinter support...'\r"
# -y to auto approve
send "sudo apt-get install -y python3-tk python3-pil.imagetk\r"
expect {
    "password" { send "$PI_PASS\r"; exp_continue }
    "$PI_USER@"
}

send "export DISPLAY=:0\r"
# Double backslash to escape for both shell and Expect?
# In Expect "send "... \$VAR ..."" sends " $VAR ".
# But we are inside a bash heredoc.
# Bash sees \$, writes \$ to file.
# Expect reads \$, sees it as literal $.
# So \\\$ in bash heredoc -> \$ in file -> literal $ in expect send string.
send "export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:\\\$PYTHONPATH\r"
send "cd $REMOTE_DIR\r"
send "python3 potholes.py\r"

puts "\n--- GUI Application Starting ---"
interact
EOF
chmod +x run_gui.exp
./run_gui.exp
rm run_gui.exp
