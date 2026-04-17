#!/usr/bin/env python3
"""
Network Monitor Service for MagicMirror WLAN Manager

Überwacht Netzwerk-Status und steuert automatisch den HotSpot:
- Prüft Internet-Konnektivität alle 30 Sekunden
- Startet HotSpot wenn kein Internet verfügbar
- Stoppt HotSpot wenn Internet-Verbindung besteht

Status wird in /tmp/wlan-status.json gespeichert für API-Zugriff
"""

import subprocess
import time
import json
import os
import sys
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, Any

# Configuration
CHECK_INTERVAL = 30  # Sekunden zwischen Checks
PING_TIMEOUT = 5  # Timeout für Ping in Sekunden
STATUS_FILE = "/tmp/wlan-status.json"
LOG_FILE = "/var/log/magicmirror-wlan/network-monitor.log"
SCRIPT_DIR = Path(__file__).parent.absolute()

# Test-Hosts für Internet-Konnektivität
PING_HOSTS = ["8.8.8.8", "1.1.1.1", "9.9.9.9"]

# Mock Mode für lokale Tests
MOCK_MODE = os.environ.get("MOCK_MODE", "false").lower() == "true"

# Setup Logging
def setup_logging():
    """Setup logging to file and console"""
    log_dir = Path(LOG_FILE).parent
    if not MOCK_MODE:
        log_dir.mkdir(parents=True, exist_ok=True)
    else:
        # In Mock Mode: Log to test directory
        global LOG_FILE
        LOG_FILE = SCRIPT_DIR.parent / "test" / "network-monitor.log"
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler(LOG_FILE),
            logging.StreamHandler(sys.stdout)
        ]
    )

def run_command(cmd: list, timeout: int = 10) -> tuple[int, str, str]:
    """
    Execute shell command and return (returncode, stdout, stderr)
    
    Args:
        cmd: Command as list
        timeout: Timeout in seconds
        
    Returns:
        Tuple of (returncode, stdout, stderr)
    """
    if MOCK_MODE:
        logging.info(f"[MOCK] Would execute: {' '.join(cmd)}")
        return (0, "mock output", "")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return (result.returncode, result.stdout, result.stderr)
    except subprocess.TimeoutExpired:
        logging.error(f"Command timed out: {' '.join(cmd)}")
        return (1, "", "Timeout")
    except Exception as e:
        logging.error(f"Command failed: {' '.join(cmd)} - {e}")
        return (1, "", str(e))

def check_internet() -> bool:
    """
    Check if internet connection is available
    
    Tries to ping multiple DNS servers. Returns True if at least one succeeds.
    
    Returns:
        True if internet is available, False otherwise
    """
    if MOCK_MODE:
        # In Mock Mode: Check if mock file says we have internet
        mock_internet_file = SCRIPT_DIR.parent / "test" / "mock-internet.txt"
        if mock_internet_file.exists():
            has_internet = mock_internet_file.read_text().strip().lower() == "true"
            logging.info(f"[MOCK] Internet status: {has_internet}")
            return has_internet
        return False
    
    for host in PING_HOSTS:
        returncode, _, _ = run_command(
            ["ping", "-c", "1", "-W", str(PING_TIMEOUT), host],
            timeout=PING_TIMEOUT + 2
        )
        if returncode == 0:
            logging.info(f"Internet check: OK (ping {host} succeeded)")
            return True
    
    logging.warning("Internet check: FAILED (all pings failed)")
    return False

def is_hotspot_active() -> bool:
    """
    Check if HotSpot is currently active
    
    Returns:
        True if HotSpot is running, False otherwise
    """
    if MOCK_MODE:
        mock_hotspot_file = SCRIPT_DIR.parent / "test" / "mock-hotspot-active.txt"
        if mock_hotspot_file.exists():
            is_active = mock_hotspot_file.read_text().strip().lower() == "true"
            logging.info(f"[MOCK] HotSpot active: {is_active}")
            return is_active
        return False
    
    # Check if hostapd process is running
    returncode, stdout, _ = run_command(["pgrep", "hostapd"], timeout=5)
    return returncode == 0

def start_hotspot() -> bool:
    """
    Start HotSpot mode
    
    Returns:
        True if successful, False otherwise
    """
    logging.info("Starting HotSpot...")
    
    script_path = SCRIPT_DIR / "start-hotspot.sh"
    returncode, stdout, stderr = run_command(["sudo", "bash", str(script_path)], timeout=30)
    
    if returncode == 0:
        logging.info("HotSpot started successfully")
        if MOCK_MODE:
            mock_file = SCRIPT_DIR.parent / "test" / "mock-hotspot-active.txt"
            mock_file.write_text("true")
        return True
    else:
        logging.error(f"Failed to start HotSpot: {stderr}")
        return False

def stop_hotspot() -> bool:
    """
    Stop HotSpot mode
    
    Returns:
        True if successful, False otherwise
    """
    logging.info("Stopping HotSpot...")
    
    script_path = SCRIPT_DIR / "stop-hotspot.sh"
    returncode, stdout, stderr = run_command(["sudo", "bash", str(script_path)], timeout=30)
    
    if returncode == 0:
        logging.info("HotSpot stopped successfully")
        if MOCK_MODE:
            mock_file = SCRIPT_DIR.parent / "test" / "mock-hotspot-active.txt"
            mock_file.write_text("false")
        return True
    else:
        logging.error(f"Failed to stop HotSpot: {stderr}")
        return False

def get_wlan_info() -> Dict[str, Any]:
    """
    Get current WLAN information
    
    Returns:
        Dictionary with WLAN info (SSID, IP, etc.)
    """
    info = {
        "connected": False,
        "ssid": None,
        "ip": None,
        "interface": "wlan0"
    }
    
    if MOCK_MODE:
        if check_internet():
            info["connected"] = True
            info["ssid"] = "MockWLAN"
            info["ip"] = "192.168.1.100"
        return info
    
    # Get SSID
    returncode, stdout, _ = run_command(["iwgetid", "-r"], timeout=5)
    if returncode == 0 and stdout.strip():
        info["ssid"] = stdout.strip()
        info["connected"] = True
    
    # Get IP address
    returncode, stdout, _ = run_command(["ip", "-4", "addr", "show", "wlan0"], timeout=5)
    if returncode == 0:
        for line in stdout.split('\n'):
            if 'inet ' in line:
                ip = line.strip().split()[1].split('/')[0]
                info["ip"] = ip
                break
    
    return info

def save_status(status: Dict[str, Any]):
    """
    Save current status to JSON file
    
    Args:
        status: Status dictionary to save
    """
    status_file = Path(STATUS_FILE)
    if MOCK_MODE:
        status_file = SCRIPT_DIR.parent / "test" / "wlan-status.json"
        status_file.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        with open(status_file, 'w') as f:
            json.dump(status, f, indent=2)
        logging.debug(f"Status saved to {status_file}")
    except Exception as e:
        logging.error(f"Failed to save status: {e}")

def monitor_loop():
    """
    Main monitoring loop
    
    Continuously checks network status and manages HotSpot
    """
    logging.info("Network Monitor started")
    logging.info(f"Mock Mode: {MOCK_MODE}")
    logging.info(f"Check interval: {CHECK_INTERVAL} seconds")
    
    while True:
        try:
            # Check current state
            has_internet = check_internet()
            hotspot_active = is_hotspot_active()
            wlan_info = get_wlan_info()
            
            # Build status object
            status = {
                "timestamp": datetime.now().isoformat(),
                "internet": has_internet,
                "hotspot_active": hotspot_active,
                "wlan": wlan_info,
                "mode": "hotspot" if hotspot_active else "client"
            }
            
            # Decision logic
            if has_internet and hotspot_active:
                # Internet available but HotSpot still running -> stop HotSpot
                logging.info("Internet available - stopping HotSpot")
                stop_hotspot()
                status["hotspot_active"] = False
                status["mode"] = "client"
                status["action"] = "stopped_hotspot"
            
            elif not has_internet and not hotspot_active:
                # No internet and HotSpot not running -> start HotSpot
                logging.info("No internet - starting HotSpot")
                start_hotspot()
                status["hotspot_active"] = True
                status["mode"] = "hotspot"
                status["action"] = "started_hotspot"
            
            else:
                # No change needed
                status["action"] = "no_change"
                logging.debug(f"Status unchanged - Internet: {has_internet}, HotSpot: {hotspot_active}")
            
            # Save status
            save_status(status)
            
            # Wait before next check
            time.sleep(CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            logging.info("Network Monitor stopped by user")
            break
        except Exception as e:
            logging.error(f"Error in monitor loop: {e}", exc_info=True)
            time.sleep(CHECK_INTERVAL)

def main():
    """Main entry point"""
    setup_logging()
    
    # Check if running as root (except in mock mode)
    if not MOCK_MODE and os.geteuid() != 0:
        logging.error("This script must be run as root")
        sys.exit(1)
    
    logging.info("="*60)
    logging.info("MagicMirror WLAN Manager - Network Monitor")
    logging.info("="*60)
    
    monitor_loop()

if __name__ == "__main__":
    main()
