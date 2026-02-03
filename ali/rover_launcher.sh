#!/bin/bash
# rover_launcher.sh - Startup Script for QSTSS Rover
# Moves to directory, sets environment, logs output

LOGfile="/home/pi/rover_startup.log"
exec > >(tee -a ${LOGfile}) 2>&1

echo "=========================================="
echo "QSTSS Rover Startup: $(date)"
echo "=========================================="

# 1. Wait for Network (Optional but good)
sleep 5

# 2. Setup Environment
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority
export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:$PYTHONPATH

cd /home/pi

# 3. Cleanup Old Locks
echo "Cleaning up..."
pkill -f potholes.py
pkill -f server.py

# 4. Permissions
echo "Setting permissions..."
sudo chmod 666 /dev/ttyACM2
# Also try others just in case
sudo chmod 666 /dev/ttyACM0 2>/dev/null
sudo chmod 666 /dev/ttyUSB0 2>/dev/null

# 5. Start Web Server (Background)
echo "Starting Web Server..."
python3 -u server.py > web.log 2>&1 &

# 6. Start GUI App (Foreground - keeps script causing wait, but for desktop entry we want it to run)
echo "Starting GUI..."
# We run it in foreground so the viewing user sees it immediately
python3 -u potholes.py > app.log 2>&1

echo "GUI closed. Startup script ending."
