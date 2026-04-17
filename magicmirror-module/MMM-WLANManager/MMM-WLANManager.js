/* global Module */

/**
 * MagicMirror Module: MMM-WLANManager
 * 
 * Zeigt QR-Codes für HotSpot-Verbindung und WebUI-Zugriff
 * wenn kein Internet verfügbar ist.
 * 
 * Auto-Hide wenn Internet-Verbindung besteht.
 */

Module.register("MMM-WLANManager", {
    // Default module config
    defaults: {
        updateInterval: 30000,  // Check every 30 seconds
        apiUrl: "http://localhost:8765",
        showWhenOnline: false,  // Hide module when internet is available
        position: "fullscreen_below",  // Show on separate page
        animationSpeed: 1000,
    },

    // Module state
    status: null,
    qrCodes: null,
    isLoading: true,
    
    // Override socket notification handler
    start: function() {
        Log.info("Starting module: " + this.name);
        
        // Load status
        this.loadStatus();
        this.loadQRCodes();
        
        // Schedule updates
        var self = this;
        setInterval(function() {
            self.loadStatus();
        }, this.config.updateInterval);
    },

    // Load status from API
    loadStatus: function() {
        this.sendSocketNotification("GET_STATUS", {
            apiUrl: this.config.apiUrl
        });
    },

    // Load QR codes from API  
    loadQRCodes: function() {
        this.sendSocketNotification("GET_QR_CODES", {
            apiUrl: this.config.apiUrl
        });
    },

    // Socket notification received
    socketNotificationReceived: function(notification, payload) {
        if (notification === "STATUS_RESULT") {
            this.status = payload;
            this.isLoading = false;
            this.updateDom(this.config.animationSpeed);
            
            // Show/hide module based on internet status
            if (!this.config.showWhenOnline) {
                if (payload.internet) {
                    this.hide(this.config.animationSpeed);
                } else {
                    this.show(this.config.animationSpeed);
                }
            }
        } else if (notification === "QR_CODES_RESULT") {
            this.qrCodes = payload;
            this.updateDom(this.config.animationSpeed);
        }
    },

    // Override dom generator
    getDom: function() {
        var wrapper = document.createElement("div");
        wrapper.className = "MMM-WLANManager";

        if (this.isLoading) {
            wrapper.innerHTML = '<div class="loading">Loading WiFi Manager...</div>';
            return wrapper;
        }

        if (!this.status) {
            wrapper.innerHTML = '<div class="error">Failed to load network status</div>';
            return wrapper;
        }

        // Header
        var header = document.createElement("div");
        header.className = "wlan-header";
        header.innerHTML = '<h1>🪞 MagicMirror WiFi Setup</h1>';
        wrapper.appendChild(header);

        // Status message
        var statusMsg = document.createElement("div");
        statusMsg.className = "status-message";
        
        if (this.status.hotspot_active) {
            statusMsg.innerHTML = `
                <div class="status-box hotspot">
                    <h2>📡 HotSpot Active</h2>
                    <p>No internet connection available. Connect your phone to configure WiFi.</p>
                </div>
            `;
        } else if (!this.status.internet) {
            statusMsg.innerHTML = `
                <div class="status-box offline">
                    <h2>⚠️ No Internet Connection</h2>
                    <p>Starting HotSpot... This may take a moment.</p>
                </div>
            `;
        } else {
            statusMsg.innerHTML = `
                <div class="status-box online">
                    <h2>✅ Connected</h2>
                    <p>Internet connection available. This screen will disappear shortly.</p>
                </div>
            `;
        }
        wrapper.appendChild(statusMsg);

        // QR Codes (only show when HotSpot is active)
        if (this.status.hotspot_active && this.qrCodes) {
            var qrSection = document.createElement("div");
            qrSection.className = "qr-section";
            
            // Instructions
            var instructions = document.createElement("div");
            instructions.className = "instructions";
            instructions.innerHTML = `
                <h3>Setup Instructions:</h3>
                <ol>
                    <li>Scan the left QR code to connect to the WiFi HotSpot</li>
                    <li>Scan the right QR code to open the configuration page</li>
                    <li>Select your WiFi network and enter the password</li>
                </ol>
            `;
            qrSection.appendChild(instructions);
            
            // QR Codes container
            var qrContainer = document.createElement("div");
            qrContainer.className = "qr-container";
            
            // HotSpot WiFi QR
            var qrHotspot = document.createElement("div");
            qrHotspot.className = "qr-item";
            qrHotspot.innerHTML = `
                <div class="qr-label">1. Connect to HotSpot</div>
                <img src="${this.qrCodes.hotspot_wifi.image}" alt="HotSpot QR Code">
                <div class="qr-details">
                    <div>SSID: <strong>MagicMirror-Setup</strong></div>
                    <div>Password: <strong>magicmirror</strong></div>
                </div>
            `;
            qrContainer.appendChild(qrHotspot);
            
            // WebUI QR
            var qrWebui = document.createElement("div");
            qrWebui.className = "qr-item";
            qrWebui.innerHTML = `
                <div class="qr-label">2. Open Configuration</div>
                <img src="${this.qrCodes.webui.image}" alt="WebUI QR Code">
                <div class="qr-details">
                    <div>URL: <strong>http://192.168.4.1:8765</strong></div>
                </div>
            `;
            qrContainer.appendChild(qrWebui);
            
            qrSection.appendChild(qrContainer);
            wrapper.appendChild(qrSection);
            
            // Alternative manual instructions
            var manualInstructions = document.createElement("div");
            manualInstructions.className = "manual-instructions";
            manualInstructions.innerHTML = `
                <p style="margin-top: 30px; opacity: 0.7;">
                    <strong>Manual Setup:</strong> Connect to WiFi "MagicMirror-Setup" (password: magicmirror), 
                    then open http://192.168.4.1:8765 in your browser.
                </p>
            `;
            wrapper.appendChild(manualInstructions);
        }

        return wrapper;
    },

    // Load custom CSS
    getStyles: function() {
        return ["MMM-WLANManager.css"];
    }
});
