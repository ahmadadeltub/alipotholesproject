from picamera2 import Picamera2
from ultralytics import YOLO
import cv2
import time
import tkinter as tk
from tkinter import ttk
import tkintermapview
from PIL import Image, ImageTk
import threading
import random
import os
import datetime
import json
import requests
import serial
import pynmea2

# Configuration
MODEL_PATH = "/home/pi/best.pt"
CAMERA_SIZE = (640, 480)
WINDOW_SIZE = "1000x600"
GPS_PORT = "/dev/ttyACM2"  # Explicitly set by user
QATAR_COORDS = (25.2854, 51.5310) # Doha
DATA_FILE = "potholes.json"

class PotholeApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Smart Road Inspection Rover")
        print(f"DEBUG: WINDOW_SIZE='{WINDOW_SIZE}'")
        self.root.geometry("1000x600") # Hardcoded to prevent variable issues
        
        # Configure layout weights
        self.root.columnconfigure(0, weight=1) # Left (Camera)
        self.root.columnconfigure(1, weight=2) # Right (Map)
        self.root.rowconfigure(0, weight=1)

        # Style
        style = ttk.Style()
        style.theme_use('clam')
        style.configure("TLabel", font=("Helvetica", 12))
        style.configure("TButton", font=("Helvetica", 12))

        # --- LEFT PANEL: Camera & Info ---
        left_panel = tk.Frame(root, bg="#2c3e50", padx=10, pady=10)
        left_panel.grid(row=0, column=0, sticky="nsew")

        # Title
        title_label = tk.Label(left_panel, text="Smart Road Inspection Rover", font=("Helvetica", 24, "bold"), fg="white", bg="#2c3e50")
        title_label.pack(pady=(0, 20))

        # Camera Frame
        self.video_label = tk.Label(left_panel, bg="black", text="Camera Feed Loading...", fg="white")
        self.video_label.pack(expand=True, fill="both", padx=5, pady=5)
        
        # Status
        self.status_label = tk.Label(left_panel, text="System: Active", font=("Helvetica", 14), fg="#2ecc71", bg="#2c3e50")
        self.status_label.pack(pady=10)

        # Quit Button
        quit_btn = tk.Button(left_panel, text="Exit System", command=self.on_close, bg="#c0392b", fg="black") # tk button for color support
        quit_btn.pack(pady=10, fill="x")

        # --- RIGHT PANEL: Map ---
        right_panel = tk.Frame(root, bg="white")
        right_panel.grid(row=0, column=1, sticky="nsew")

        self.map_widget = tkintermapview.TkinterMapView(right_panel, width=600, height=600, corner_radius=0)
        self.map_widget.pack(fill="both", expand=True)

        # Set Default to Google Hybrid
        self.map_widget.set_tile_server("https://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}&s=Ga", max_zoom=22)
        self.map_widget.set_position(QATAR_COORDS[0], QATAR_COORDS[1])
        self.map_widget.set_zoom(12)

        # Database of images (In a real app, this would be dynamic)
        self.pothole_images = {
            "Loc1": "pothole1.png",
            "Loc2": "pothole2.png",
            "Loc3": "pothole3.png",
            "Specific Point": "pothole5.png",
            "Highway Alert": "pothole4.png",
            "Desert Rd": "pothole6.png",
            "Corniche View": "pothole1.png",
            "West Bay Entry": "pothole2.png",
            "Souq Area": "pothole3.png",
            "Airport Rd": "pothole4.png",
            "Pearl Access": "pothole5.png",
            "University St": "pothole6.png"
        }
        
        # Add Markers
        self.pothole_data_list = []
        self.load_data()
        self.add_sample_markers()
        
        # --- SYNC DATA (Initial) ---
        self.sync_data_to_file()

        # --- MAP CONTROLS ---
        self.create_map_controls(right_panel)

        # --- CAMERA SETUP ---
        self.current_frame = None # Store latest frame for capture
        try:
            self.picam2 = Picamera2()
            self.picam2.preview_configuration.main.size = CAMERA_SIZE
            self.picam2.preview_configuration.main.format = "RGB888"
            self.picam2.configure("preview")
            self.picam2.start()
            self.camera_active = True
        except Exception as e:
            print(f"Camera Error: {e}")
            self.video_label.configure(text=f"Camera Error:\n{e}")
            self.camera_active = False

        # --- MODEL SETUP ---
        self.model = None
        threading.Thread(target=self.load_model, daemon=True).start()

        # --- GPS SETUP ---
        self.gps_lat = None
        self.gps_lon = None
        threading.Thread(target=self.read_gps_data, daemon=True).start()
        
        # --- AUTO-SYNC GPS ---
        self.root.after(5000, self.auto_sync_rover_location)

        self.running = True
        if self.camera_active:
            self.update_frame()
            
    def auto_sync_rover_location(self):
        if self.running:
            # 1. FIRST: Sync Pothole Status & Deletions FROM File (Server -> GUI)
            # This MUST happen BEFORE we write anything back
            try:
                if os.path.exists(DATA_FILE):
                    with open(DATA_FILE, 'r') as f:
                        file_data = json.load(f)
                    
                    remote_map = {d['id']: d.get('status') for d in file_data}
                    remote_ids = set(remote_map.keys())
                    
                    # A. Detect Deletions (In Local but not in Remote)
                    # Don't delete "Current Location"
                    items_to_remove = []
                    for item in self.pothole_data_list:
                        if item['id'] != "Current Location" and item['id'] not in remote_ids:
                             items_to_remove.append(item)
                    
                    needs_refresh = False
                    if items_to_remove:
                        for item in items_to_remove:
                            print(f"Sync: Removing deleted item {item['id']}")
                            self.pothole_data_list.remove(item)
                        needs_refresh = True

                    # B. Detect Status Changes
                    for item in self.pothole_data_list:
                        if item['id'] == "Current Location": continue
                        
                        remote_status = remote_map.get(item['id'])
                        if remote_status and item.get('status') != remote_status:
                            item['status'] = remote_status
                            needs_refresh = True
                    
                    if needs_refresh:
                        self.refresh_markers()

            except Exception as e:
                print(f"Sync read error: {e}")

            # 2. THEN: Update Rover Location (GPS -> Local List)
            if self.gps_lat is not None and self.gps_lon is not None:
                for item in self.pothole_data_list:
                    if item['id'] == "Current Location":
                        item['lat'] = self.gps_lat
                        item['lon'] = self.gps_lon
                        if hasattr(self, 'current_loc_marker'):
                            self.current_loc_marker.set_position(self.gps_lat, self.gps_lon)
                        break
            
            # 3. FINALLY: Write back to file (only updates rover location now)
            self.sync_data_to_file()

            # Repeat every 5 seconds
            self.root.after(5000, self.auto_sync_rover_location)

    def read_gps_data(self):
        # Try configured port first, then fallbacks
        ports = [GPS_PORT, '/dev/ttyUSB0', '/dev/ttyACM0', '/dev/ttyAMA0']
        ser = None
        
        for port in ports:
            try:
                ser = serial.Serial(port, 9600, timeout=1)
                print(f"GPS Connected on {port}")
                break
            except:
                continue
                
        if not ser:
            print("No GPS Hardware Found")
            return

        while True:
            try:
                line = ser.readline().decode('utf-8', errors='ignore')
                if line.startswith('$GPGGA') or line.startswith('$GPRMC'):
                    msg = pynmea2.parse(line)
                    if hasattr(msg, 'latitude') and msg.latitude != 0:
                        self.gps_lat = msg.latitude
                        self.gps_lon = msg.longitude
                        # print(f"GPS Fix: {self.gps_lat}, {self.gps_lon}")
            except Exception as e:
                # print(f"GPS Parse Error: {e}")
                pass

    def create_map_controls(self, parent):
        # Floating control panel or bottom bar
        control_frame = tk.Frame(parent, bg="white", borderwidth=2, relief="raised")
        control_frame.place(relx=0.95, rely=0.95, anchor="se") # Bottom right corner

        # 1. Navigation Pad
        nav_frame = tk.Frame(control_frame, bg="white")
        nav_frame.pack(side="top", padx=5, pady=5)
        
        btn_opts = {"width": 3, "bg": "#ecf0f1", "font": ("Arial", 10, "bold")}

        tk.Button(nav_frame, text="▲", command=lambda: self.move_map(0.005, 0), **btn_opts).grid(row=0, column=1, padx=2, pady=2)
        tk.Button(nav_frame, text="◀", command=lambda: self.move_map(0, -0.005), **btn_opts).grid(row=1, column=0, padx=2, pady=2)
        tk.Button(nav_frame, text="⌖", command=self.go_to_current_location, bg="#3498db", fg="white", font=("Arial", 10, "bold"), width=3).grid(row=1, column=1, padx=2, pady=2)
        tk.Button(nav_frame, text="▶", command=lambda: self.move_map(0, 0.005), **btn_opts).grid(row=1, column=2, padx=2, pady=2)
        tk.Button(nav_frame, text="▼", command=lambda: self.move_map(-0.005, 0), **btn_opts).grid(row=2, column=1, padx=2, pady=2)

        # Separator
        ttk.Separator(control_frame, orient="horizontal").pack(fill="x", pady=5)

        # 2. View Options
        view_frame = tk.Frame(control_frame, bg="white")
        view_frame.pack(side="top", padx=5, pady=5)
        
        self.current_map_mode = 0
        self.map_modes = ["Google Hybrid", "Google Road", "OSM"]
        
        # Set Default to Google Hybrid already done in init, just set button txt
        self.btn_mode = tk.Button(view_frame, text="Map: Hybrid", command=self.cycle_map_mode, bg="#95a5a6", fg="black", width=12)
        self.btn_mode.pack(pady=2)
        
        # 3. Pin & Capture Action
        tk.Button(view_frame, text="📍 PIN & CAPTURE", command=self.pin_and_capture, bg="#e74c3c", fg="white", font=("Arial", 10, "bold"), width=15).pack(pady=5)

    def move_map(self, d_lat, d_lon):
        # Get current position
        lat, lon = self.map_widget.get_position()
        self.map_widget.set_position(lat + d_lat, lon + d_lon)

    def get_real_location(self):
        # 1. Prefer Hardware GPS
        if self.gps_lat is not None and self.gps_lon is not None:
            return self.gps_lat, self.gps_lon

        # 2. Fallback to IP Geolocation
        try:
            # Short timeout to avoid freezing UI
            response = requests.get("http://ip-api.com/json/", timeout=3)
            data = response.json()
            if data['status'] == 'success':
                return data['lat'], data['lon']
        except Exception as e:
            print(f"GeoIP Error: {e}")
            
        # 3. Last Resort
        return QATAR_COORDS

    def go_to_current_location(self):
        lat, lon = self.get_real_location()
        
        # Move Map
        self.map_widget.set_position(lat, lon)
        self.map_widget.set_zoom(15)
        
        # Update Marker Position
        if hasattr(self, 'current_loc_marker') and self.current_loc_marker:
            self.current_loc_marker.set_position(lat, lon)
        else:
             self.current_loc_marker = self.map_widget.set_marker(lat, lon, text="Current Location", marker_color_circle="blue", marker_color_outside="white")
        
        self.status_label.config(text=f"Loc: {lat:.4f}, {lon:.4f}")
        
        # UPDATE & SYNC "Current Location" in Data List
        # Check if exists
        found = False
        for item in self.pothole_data_list:
            if item['id'] == "Current Location":
                item['lat'] = lat
                item['lon'] = lon
                found = True
                break
        
        if not found:
             self.pothole_data_list.append({
                "id": "Current Location",
                "lat": lat,
                "lon": lon,
                "image": None,
                "date": "Live",
                "type": "rover"
             })
             
        self.sync_data_to_file()

    def cycle_map_mode(self):
        self.current_map_mode = (self.current_map_mode + 1) % 3
        mode = self.map_modes[self.current_map_mode]
        self.btn_mode.config(text=f"Map: {mode}")
        
        if mode == "Google Hybrid":
            self.map_widget.set_tile_server("https://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}&s=Ga", max_zoom=22)
        elif mode == "Google Road":
            self.map_widget.set_tile_server("https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga", max_zoom=22)
        elif mode == "OSM":
            self.map_widget.set_tile_server("https://a.tile.openstreetmap.org/{z}/{x}/{y}.png")

    def load_model(self):
        try:
            print("Loading YOLO model...")
            self.model = YOLO(MODEL_PATH)
            print("Model loaded.")
            self.status_label.config(text="System: Detecting")
        except Exception as e:
            print(f"Model Error: {e}")
            self.status_label.config(text="System: AI Error", fg="red")

    def load_data(self):
        if os.path.exists(DATA_FILE):
            try:
                with open(DATA_FILE, 'r') as f:
                    data = json.load(f)
                    
                for item in data:
                    # Deduplicate
                    if any(d['id'] == item['id'] for d in self.pothole_data_list):
                        continue

                    # Special handling for Current Location to bind to self.current_loc_marker
                    if item['id'] == "Current Location":
                        self.current_loc_marker = self.map_widget.set_marker(
                            item['lat'], item['lon'], text="Current Location", 
                            marker_color_circle="blue", marker_color_outside="white"
                        )
                        self.pothole_data_list.append(item)
                        continue

                    # Determine color/text format
                    is_capture = "Capture" in item['id']
                    marker_color = "red" if is_capture else "orange" # Captures red, samples orange
                    text_prefix = "New Pothole" if is_capture else "Pothole Alert"
                    
                    # Add to internal list
                    self.pothole_data_list.append(item)
                    
                    # Register image for popup
                    self.pothole_images[item['id']] = item['image']
                    
                    # Add marker to map
                    self.map_widget.set_marker(
                        item['lat'], 
                        item['lon'], 
                        text=f"{text_prefix}: {item['id']}", 
                        marker_color_circle=marker_color,
                        command=lambda m: self.show_pothole_image(m.text)
                    )
                print(f"Loaded {len(data)} markers from file.")
            except Exception as e:
                print(f"Error loading data: {e}")

    def refresh_markers(self):
        # Clear existing markers (except stored list)
        self.map_widget.delete_all_marker()
        
        # Re-add based on current data list
        for item in self.pothole_data_list:
            if item['id'] == "Current Location":
                self.current_loc_marker = self.map_widget.set_marker(
                    item['lat'], item['lon'], text="Current Location", 
                    marker_color_circle="blue", marker_color_outside="white"
                )
                continue

            # Determine color
            is_fixed = item.get('status') == 'fixed'
            is_capture = "Capture" in item['id']
            
            if is_fixed:
                marker_color = "green" # Green for fixed
            else:
                marker_color = "red" if is_capture else "orange"
            
            text_labels = f"{item['id']}"
            if is_fixed: text_labels += " (Fixed)"

            self.map_widget.set_marker(
                item['lat'], item['lon'], 
                text=text_labels, 
                marker_color_circle=marker_color,
                command=lambda m: self.show_pothole_image(m.text)
            )

    def add_sample_markers(self):
        # 1. Current Location (Simulated Center/Start)
        # Ensure it exists in data list
        if not any(d['id'] == "Current Location" for d in self.pothole_data_list):
            self.current_loc_marker = self.map_widget.set_marker(QATAR_COORDS[0], QATAR_COORDS[1], text="Current Location", marker_color_circle="blue", marker_color_outside="white")
            self.pothole_data_list.append({
                "id": "Current Location",
                "lat": QATAR_COORDS[0],
                "lon": QATAR_COORDS[1],
                "image": None,
                "date": "Default",
                "type": "rover"
            })
        elif not hasattr(self, 'current_loc_marker'): 
            # If loaded from file, ensure we have the marker ref
             # (Actually load_data handles this, but good safety)
             pass

        # 3. ONLY add sample potholes on FIRST-TIME SETUP (no existing JSON)
        # This prevents deleted items from being re-added
        if os.path.exists(DATA_FILE):
            # JSON exists, so user has data. Do NOT add samples.
            return
            
        # First-time setup: add samples
        locations = [
            (25.206197, 51.466170, "Specific Point"),
            (25.2854, 51.5360, "Loc1"), 
            (25.2954, 51.5210, "Loc2"),
            (25.2754, 51.5410, "Loc3"),
            (25.2100, 51.4700, "Highway Alert"),
            (25.3000, 51.5000, "Desert Rd"),
            (25.2800, 51.5300, "Corniche View"),
            (25.2900, 51.5400, "West Bay Entry"),
            (25.2700, 51.5200, "Souq Area"),
            (25.2600, 51.5100, "Airport Rd"),
            (25.2500, 51.5500, "Pearl Access"),
            (25.3100, 51.4900, "University St")
        ]
        
        for lat, lon, name in locations:
            self.map_widget.set_marker(lat, lon, text=f"Pothole Alert: {name}", command=lambda m: self.show_pothole_image(m.text))
            
            self.pothole_data_list.append({
                "id": name,
                "lat": lat,
                "lon": lon,
                "image": self.pothole_images.get(name),
                "date": "Sample"
             })

    # Redeclare sync properly
    def sync_data_to_file(self):
        try:
            with open(DATA_FILE, 'w') as f:
                json.dump(self.pothole_data_list, f)
        except Exception as e:
            print(f"Failed to sync data: {e}")
            
    # Update pin_capture to store data
    def pin_and_capture(self):
        # 1. Capture Image
        if self.current_frame is None:
            print("No frame to capture")
            return
            
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"capture_{timestamp}.jpg"
        
        try:
            img = Image.fromarray(self.current_frame)
            img.save(filename)
            print(f"Saved {filename}")
            
            # 2. Add Marker on Map at ROVER's current GPS location
            if self.gps_lat is not None and self.gps_lon is not None:
                lat, lon = self.gps_lat, self.gps_lon
            else:
                # Fallback to map center if no GPS fix
                lat, lon = self.map_widget.get_position()
            
            # Small random offset to avoid stacking
            lat += (random.random() - 0.5) * 0.00005
            lon += (random.random() - 0.5) * 0.00005
            
            identifier = f"Capture_{timestamp}"
            self.pothole_images[identifier] = filename
            
            self.map_widget.set_marker(lat, lon, text=f"New Pothole: {identifier}", marker_color_circle="red", command=lambda m: self.show_pothole_image(m.text))
            
            # Store in Data List
            self.pothole_data_list.append({
                "id": identifier,
                "lat": lat,
                "lon": lon,
                "image": filename,
                "date": timestamp
            })
            
            # Sync to file (propagates to Web)
            self.sync_data_to_file()
            
            # Refresh GUI markers
            self.refresh_markers()
            
            # Feedback
            self.status_label.config(text=f"Pinned: {identifier}")
            
        except Exception as e:
            print(f"Capture failed: {e}")

    def show_pothole_image(self, marker_text):
        # Parse name from text "Pothole Alert: Loc1" or "New Pothole: Capture_..."
        loc_name = marker_text.split(": ")[-1]
        image_file = self.pothole_images.get(loc_name)
        
        if image_file and os.path.exists(image_file):
            top = tk.Toplevel(self.root)
            top.title(f"Evidence: {loc_name}")
            top.geometry("400x400")
            
            try:
                img = Image.open(image_file)
                img = img.resize((380, 380), Image.LANCZOS)
                photo = ImageTk.PhotoImage(img)
                
                lbl = tk.Label(top, image=photo)
                lbl.image = photo # Keep reference
                lbl.pack(padx=10, pady=10)
                
                # Action Buttons
                btn_frame = tk.Frame(top)
                btn_frame.pack(fill="x", pady=5)
                
                # Delete Button
                def delete_item():
                    # Remove from list
                    self.pothole_data_list = [d for d in self.pothole_data_list if d['id'] != loc_name]
                    # Sync to file
                    self.sync_data_to_file()
                    # Refresh Map
                    self.refresh_markers()
                    top.destroy()
                    print(f"Deleted {loc_name}")

                tk.Button(btn_frame, text="DELETE PERMANENTLY", command=delete_item, bg="red", fg="white").pack(pady=5)

            except Exception as e:
                tk.Label(top, text=f"Error loading image: {e}").pack()
        else:
            print(f"Image not found: {image_file}")

    def update_frame(self):
        if not self.running:
            return

        try:
            frame = self.picam2.capture_array()
            self.current_frame = frame # Save for capture
            
            # Inference if model loaded
            if self.model:
                results = self.model(frame, imgsz=320, conf=0.4, device="cpu", verbose=False)
                frame = results[0].plot() # This returns BGR usually

            # Convert for Tkinter (BGR -> RGB -> Image -> ImageTk)
            # OpenCV uses BGR, PIL uses RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(frame_rgb)
            imgtk = ImageTk.PhotoImage(image=img)

            self.video_label.imgtk = imgtk
            self.video_label.configure(image=imgtk, text="") # Clear text if image present
            
        except Exception as e:
            print(f"Frame Error: {e}")

        self.root.after(30, self.update_frame)

    def on_close(self):
        self.running = False
        try:
            if self.camera_active:
                self.picam2.stop()
        except:
            pass
        self.root.destroy()
        os._exit(0) # Force exit threads

if __name__ == "__main__":
    root = tk.Tk()
    app = PotholeApp(root)
    root.protocol("WM_DELETE_WINDOW", app.on_close)
    root.mainloop()
