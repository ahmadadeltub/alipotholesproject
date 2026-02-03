from flask import Flask, render_template, jsonify, send_from_directory
import json
import os

app = Flask(__name__)
DATA_FILE = "potholes.json"

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/potholes')
def get_potholes():
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
            return jsonify(data)
        except:
            return jsonify([])
    return jsonify([])

@app.route('/api/resolve', methods=['POST'])
def resolve_pothole():
    try:
        from flask import request
        item_id = request.json.get('id')
        new_status = request.json.get('status', 'fixed') # Default to fixed if not sent
        if not item_id: return jsonify({"success": False})

        # Load existing
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
            
            if new_status == 'deleted':
                 # Filter out the item
                 data = [d for d in data if d['id'] != item_id]
            else:
                # Update status
                for d in data:
                    if d['id'] == item_id:
                        d['status'] = new_status
                        break
            
            # Save back
            with open(DATA_FILE, 'w') as f:
                json.dump(data, f)
                
            return jsonify({"success": True})
    except Exception as e:
        print(e)
    return jsonify({"success": False})

@app.route('/images/<path:filename>')
def serve_image(filename):
    return send_from_directory('.', filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
