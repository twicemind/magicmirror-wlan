/* global require */

/**
 * Node Helper for MMM-WLANManager
 * 
 * Handles API calls to the WLAN WebUI backend
 */

var NodeHelper = require("node_helper");
var axios = require("axios");

module.exports = NodeHelper.create({
    
    // Socket notification received from module
    socketNotificationReceived: function(notification, payload) {
        var self = this;
        
        if (notification === "GET_STATUS") {
            this.getStatus(payload.apiUrl);
        } else if (notification === "GET_QR_CODES") {
            this.getQRCodes(payload.apiUrl);
        }
    },
    
    // Get network status from API
    getStatus: function(apiUrl) {
        var self = this;
        var url = apiUrl + "/api/status";
        
        axios.get(url, { timeout: 5000 })
            .then(function(response) {
                if (response.data && response.data.success) {
                    self.sendSocketNotification("STATUS_RESULT", response.data.status);
                } else {
                    console.error("MMM-WLANManager: API returned error");
                }
            })
            .catch(function(error) {
                console.error("MMM-WLANManager: Failed to get status:", error.message);
                // Send offline status
                self.sendSocketNotification("STATUS_RESULT", {
                    internet: false,
                    hotspot_active: false,
                    mode: "unknown"
                });
            });
    },
    
    // Get QR codes from API
    getQRCodes: function(apiUrl) {
        var self = this;
        var url = apiUrl + "/api/qr-data";
        
        axios.get(url, { timeout: 5000 })
            .then(function(response) {
                if (response.data && response.data.success) {
                    self.sendSocketNotification("QR_CODES_RESULT", response.data.qr_codes);
                } else {
                    console.error("MMM-WLANManager: Failed to get QR codes");
                }
            })
            .catch(function(error) {
                console.error("MMM-WLANManager: Failed to get QR codes:", error.message);
            });
    }
});
