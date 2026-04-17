#!/usr/bin/env python3
"""
WebUI for MagicMirror WLAN Manager

Provides web interface for WLAN configuration:
- Scan available WiFi networks
- Configure WLAN credentials
- Show current status
- Generate QR codes for MagicMirror module

Runs on port 8765
"""

from flask import Flask, render_template, jsonify, request
import subprocess
import json
import os
import sys
import io
import base64
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
import qrcode

app = Flask(__name__)

# Configuration
SCRIPT_DIR = Path(__file__).parent.parent / "scripts"
STATUS_FILE = Path("/tmp/wlan-status.json")
PORT = 8765
HOST = "0.0.0.0"

# Mock Mode für Tests
MOCK_MODE = os.environ.get("MOCK_MODE", "false").lower() == "true"

if MOCK_MODE:
    STATUS_FILE = Path(__file__).parent.parent / "test" / "wlan-status.json"
    print("[MOCK MODE] Running in test mode")

def run_command(cmd: list, timeout: int = 10) -> tuple[int, str, str]:
    """Execute shell command"""
    if MOCK_MODE:
        print(f"[MOCK] Would execute: {' '.join(cmd)}")
        return (0, "mock output", "")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return (result.returncode, result.stdout, result.stderr)
    except subprocess.TimeoutExpired:
        return (1, "", "Timeout")
    except Exception as e:
        return (1, "", str(e))

def get_status() -> Dict[str, Any]:
    """
    Get current network status from file
    
    Returns:
        Status dictionary
    """
    if STATUS_FILE.exists():
        try:
            with open(STATUS_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error reading status file: {e}")
    
    return {
        "timestamp": datetime.now().isoformat(),
        "internet": False,
        "hotspot_active": False,
        "mode": "unknown",
        "wlan": {
            "connected": False,
            "ssid": None,
            "ip": None
        }
    }

def scan_networks() -> List[Dict[str, Any]]:
    """
    Scan for available WiFi networks
    
    Returns:
        List of networks with SSID, signal strength, encryption
    """
    if MOCK_MODE:
        return [
            {"ssid": "HomeWiFi", "signal": -45, "encryption": "WPA2", "channel": 6},
            {"ssid": "Neighbor_5G", "signal": -67, "encryption": "WPA2", "channel": 36},
            {"ssid": "FreeWiFi", "signal": -82, "encryption": "Open", "channel": 11},
        ]
    
    networks = []
    
    # Use iwlist to scan (works on Raspberry Pi)
    returncode, stdout, stderr = run_command(["sudo", "iwlist", "wlan0", "scan"], timeout=15)
    
    if returncode != 0:
        print(f"WiFi scan failed: {stderr}")
        return networks
    
    # Parse iwlist output
    current_network = {}
    for line in stdout.split('\n'):
        line = line.strip()
        
        if 'Cell' in line and 'Address' in line:
            # Start of new network
            if current_network and 'ssid' in current_network:
                networks.append(current_network)
            current_network = {}
        
        elif 'ESSID:' in line:
            ssid = line.split('ESSID:')[1].strip('"')
            if ssid:  # Skip hidden networks
                current_network['ssid'] = ssid
        
        elif 'Signal level=' in line:
            # Extract signal strength
            signal = line.split('Signal level=')[1].split()[0]
            try:
                current_network['signal'] = int(signal)
            except ValueError:
                current_network['signal'] = -100
        
        elif 'Encryption key:' in line:
            has_encryption = 'on' in line
            current_network['encryption'] = 'Encrypted' if has_encryption else 'Open'
        
        elif 'IE: IEEE 802.11i/WPA2' in line:
            current_network['encryption'] = 'WPA2'
        
        elif 'IE: WPA Version' in line:
            current_network['encryption'] = 'WPA'
        
        elif 'Channel:' in line:
            try:
                channel = int(line.split('Channel:')[1].strip())
                current_network['channel'] = channel
            except:
                pass
    
    # Add last network
    if current_network and 'ssid' in current_network:
        networks.append(current_network)
    
    # Sort by signal strength (strongest first)
    networks.sort(key=lambda x: x.get('signal', -100), reverse=True)
    
    return networks

def generate_qr_code(data: str) -> str:
    """
    Generate QR code as base64 PNG
    
    Args:
        data: Data to encode in QR code
        
    Returns:
        Base64 encoded PNG image
    """
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Convert to base64
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    
    return f"data:image/png;base64,{img_str}"

@app.route('/')
def index():
    """Main page"""
    return render_template('index.html')

@app.route('/api/status')
def api_status():
    """Get current network status"""
    try:
        status = get_status()
        return jsonify({
            "success": True,
            "status": status
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/networks')
def api_networks():
    """Scan and return available WiFi networks"""
    try:
        networks = scan_networks()
        return jsonify({
            "success": True,
            "networks": networks,
            "count": len(networks)
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/configure', methods=['POST'])
def api_configure():
    """
    Configure WLAN
    
    Expected JSON:
    {
        "ssid": "MyWiFi",
        "password": "secret123",
        "encryption": "WPA2-PSK"
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'ssid' not in data or 'password' not in data:
            return jsonify({
                "success": False,
                "error": "Missing required fields: ssid, password"
            }), 400
        
        ssid = data['ssid']
        password = data['password']
        encryption = data.get('encryption', 'WPA-PSK')
        
        # Validate password length
        if len(password) < 8:
            return jsonify({
                "success": False,
                "error": "Password must be at least 8 characters"
            }), 400
        
        # Run configuration script
        script_path = SCRIPT_DIR / "configure-wlan.sh"
        
        if MOCK_MODE:
            os.environ["MOCK_MODE"] = "true"
        
        returncode, stdout, stderr = run_command([
            "sudo", "bash", str(script_path), ssid, password, encryption
        ], timeout=30)
        
        if returncode == 0:
            return jsonify({
                "success": True,
                "message": "WLAN configured successfully",
                "ssid": ssid
            })
        else:
            return jsonify({
                "success": False,
                "error": f"Configuration failed: {stderr}"
            }), 500
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/qr-data')
def api_qr_data():
    """
    Get QR code data for HotSpot and WebUI
    
    Returns:
        QR codes as base64 PNG images
    """
    try:
        status = get_status()
        
        # HotSpot WLAN QR Code (WiFi format)
        # Format: WIFI:T:WPA;S:ssid;P:password;;
        hotspot_ssid = "MagicMirror-Setup"
        hotspot_password = "magicmirror"
        wifi_qr_data = f"WIFI:T:WPA;S:{hotspot_ssid};P:{hotspot_password};;"
        
        # WebUI URL QR Code
        if status.get('hotspot_active', False):
            webui_url = "http://192.168.4.1:8765"
        else:
            # In client mode: use current IP
            wlan_ip = status.get('wlan', {}).get('ip', '192.168.1.1')
            webui_url = f"http://{wlan_ip}:8765"
        
        return jsonify({
            "success": True,
            "qr_codes": {
                "hotspot_wifi": {
                    "data": wifi_qr_data,
                    "image": generate_qr_code(wifi_qr_data),
                    "label": f"Connect to: {hotspot_ssid}"
                },
                "webui": {
                    "data": webui_url,
                    "image": generate_qr_code(webui_url),
                    "label": "Open WebUI"
                }
            },
            "hotspot_credentials": {
                "ssid": hotspot_ssid,
                "password": hotspot_password
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

def main():
    """Main entry point"""
    print("="*60)
    print("MagicMirror WLAN Manager - WebUI")
    print("="*60)
    print(f"Mock Mode: {MOCK_MODE}")
    print(f"Starting on http://{HOST}:{PORT}")
    print("="*60)
    
    # Run Flask app
    app.run(
        host=HOST,
        port=PORT,
        debug=MOCK_MODE  # Debug mode nur in Tests
    )

if __name__ == '__main__':
    main()
