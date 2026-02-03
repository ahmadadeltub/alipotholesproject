#!/bin/bash
# Wait for X environment
sleep 10

export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority
export PYTHONPATH=/home/pi/.local/lib/python3.13/site-packages:$PYTHONPATH
cd /home/pi

echo "==========================" >> startup.log
echo "Rover Startup: $(date)" >> startup.log
echo "==========================" >> startup.log

# 1. Start Web Server (Background)
echo "Starting Web Server..." >> startup.log
python3 server.py >> web.log 2>&1 &

# 2. Start Main App (Background/Foreground)
echo "Starting Main App..." >> startup.log
# We run in background so the script exits, but the process stays alive
python3 potholes.py >> app.log 2>&1 &

echo "Startup commands issued." >> startup.log
