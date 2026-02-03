# 🚗 Smart Road Inspection Rover

**Designed by QSTSS School**

An intelligent pothole detection and mapping system using a Raspberry Pi-based rover with real-time GPS tracking, web dashboard, and AI-powered detection.

![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)
![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-5-red?logo=raspberrypi)
![Flask](https://img.shields.io/badge/Flask-3.0+-green?logo=flask)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

- **🤖 AI Pothole Detection**: Uses YOLO model to automatically detect potholes from camera feed
- **📍 Real-Time GPS Tracking**: USB GPS module provides accurate rover location
- **🗺️ Interactive Web Dashboard**: View all potholes on a Google Maps-style interface
- **📱 Mobile-Friendly**: Access the dashboard from any phone or tablet
- **🔄 Two-Way Sync**: Changes on web instantly reflect on the rover GUI and vice versa
- **✅ Status Management**: Mark potholes as "Fixed" (green) or delete them permanently
- **📷 Photo Capture**: Capture pothole images with GPS coordinates
- **🚀 Auto-Start**: System launches automatically on Raspberry Pi boot

## 🛠️ Hardware Requirements

| Component | Description |
|-----------|-------------|
| Raspberry Pi 5 | Main controller |
| USB Camera | For pothole detection |
| USB GPS Module | VFAN or similar (NMEA compatible) |
| 7" Touchscreen | For GUI display |
| Power Supply | 5V/5A for Pi |

## 📦 Software Dependencies

```bash
# Install on Raspberry Pi
pip3 install flask requests pyserial pynmea2 pillow tkintermapview ultralytics --break-system-packages
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/smart-rover.git
cd smart-rover
```

### 2. Deploy to Raspberry Pi
```bash
# Edit deploy_all.sh with your Pi's IP address
./deploy_all.sh
```

### 3. Access the Dashboard
Open in your browser:
```
http://<PI_IP_ADDRESS>:5000
```

## 📁 Project Structure

```
smart-rover/
├── potholes.py          # Main GUI application
├── server.py            # Flask web server
├── rover_launcher.sh    # Auto-start script
├── rover.desktop        # Desktop autostart entry
├── deploy_all.sh        # Deployment script
├── templates/
│   └── index.html       # Web dashboard
├── pothole1-6.png       # Sample pothole images
├── rover_icon.png       # Rover marker icon
└── potholes.json        # Data storage (auto-generated)
```

## 🎮 Usage

### Web Dashboard
- **🔴 Red Markers**: Active potholes
- **🟢 Green Markers**: Fixed potholes  
- **🔵 Blue Icon**: Rover's current location
- **📍 Blue Dot**: Your phone's GPS location

### Actions
| Button | Action |
|--------|--------|
| Navigate ➔ | Open Google Maps directions |
| ✅ Fixed | Mark pothole as repaired |
| Undo | Revert fixed status |
| 🗑️ | Delete pothole permanently |

### Rover GUI
- **Start/Stop Camera**: Toggle AI detection
- **Capture**: Take photo and pin pothole at rover's GPS location
- **Click markers**: View pothole image and delete option

## ⚙️ Configuration

Edit `potholes.py` to customize:

```python
MODEL_PATH = "/home/pi/best.pt"      # YOLO model path
GPS_PORT = "/dev/ttyACM2"            # GPS serial port
QATAR_COORDS = (25.2854, 51.5310)    # Default map center
CAMERA_SIZE = (640, 480)             # Camera resolution
```

## 🔧 Troubleshooting

### GPS Not Working
```bash
# Check available ports
ls /dev/tty*

# Test GPS output
cat /dev/ttyACM0
```

### Camera Issues
```bash
# List cameras
v4l2-ctl --list-devices

# Test camera
libcamera-hello
```

### Web Dashboard Blank
- Clear browser cache
- Check server logs: `cat /home/pi/web.log`

## 📸 Screenshots

| GUI Map | Web Dashboard |
|---------|---------------|
| Tkinter-based map with markers | Mobile-friendly web interface |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- **QSTSS School** - Project design and development
- [TkinterMapView](https://github.com/TomSchimansky/TkinterMapView) - Interactive map widget
- [Leaflet.js](https://leafletjs.com/) - Web mapping library
- [Ultralytics YOLO](https://github.com/ultralytics/ultralytics) - AI detection model

---

**Made with ❤️ by QSTSS School**
