// MagicMirror WLAN Manager - Frontend JavaScript

let currentNetworks = [];
let refreshInterval = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadStatus();
    loadQRCodes();
    
    // Auto-refresh status every 10 seconds
    refreshInterval = setInterval(() => {
        loadStatus();
    }, 10000);
    
    // Handle encryption change
    document.getElementById('encryption').addEventListener('change', (e) => {
        const passwordGroup = document.getElementById('password-group');
        if (e.target.value === 'Open') {
            passwordGroup.style.display = 'none';
            document.getElementById('password').required = false;
        } else {
            passwordGroup.style.display = 'block';
            document.getElementById('password').required = true;
        }
    });
});

// Load network status
async function loadStatus() {
    try {
        const response = await fetch('/api/status');
        const data = await response.json();
        
        if (data.success) {
            updateStatusUI(data.status);
        } else {
            console.error('Failed to load status:', data.error);
        }
    } catch (error) {
        console.error('Error loading status:', error);
    }
}

// Update status UI
function updateStatusUI(status) {
    const statusIndicator = document.getElementById('status-indicator');
    const hotspotInfo = document.getElementById('hotspot-info');
    
    // Update status indicator
    statusIndicator.className = 'status-indicator';
    if (status.internet) {
        statusIndicator.classList.add('online');
        document.querySelector('.status-text').textContent = 'Online';
    } else if (status.hotspot_active) {
        statusIndicator.classList.add('hotspot');
        document.querySelector('.status-text').textContent = 'HotSpot Active';
    } else {
        statusIndicator.classList.add('offline');
        document.querySelector('.status-text').textContent = 'Offline';
    }
    
    // Show/hide HotSpot info
    hotspotInfo.style.display = status.hotspot_active ? 'block' : 'none';
    
    // Update status details
    document.getElementById('status-mode').textContent = status.mode || '-';
    document.getElementById('status-internet').textContent = status.internet ? '✅ Connected' : '❌ Not connected';
    document.getElementById('status-ssid').textContent = status.wlan?.ssid || '-';
    document.getElementById('status-ip').textContent = status.wlan?.ip || '-';
    
    // Update last update time
    const lastUpdate = new Date(status.timestamp);
    document.getElementById('last-update').textContent = lastUpdate.toLocaleTimeString();
}

// Scan for WiFi networks
async function scanNetworks() {
    const scanBtn = document.getElementById('scan-btn');
    const networksList = document.getElementById('networks-list');
    const networksContent = document.getElementById('networks-content');
    
    // Show loading state
    scanBtn.disabled = true;
    scanBtn.querySelector('.btn-text').innerHTML = '<span class="loading"></span> Scanning...';
    
    try {
        const response = await fetch('/api/networks');
        const data = await response.json();
        
        if (data.success) {
            currentNetworks = data.networks;
            displayNetworks(data.networks);
            networksList.style.display = 'block';
        } else {
            alert('Failed to scan networks: ' + data.error);
        }
    } catch (error) {
        console.error('Error scanning networks:', error);
        alert('Error scanning networks. Please try again.');
    } finally {
        scanBtn.disabled = false;
        scanBtn.querySelector('.btn-text').textContent = 'Scan for Networks';
    }
}

// Display networks list
function displayNetworks(networks) {
    const networksContent = document.getElementById('networks-content');
    
    if (networks.length === 0) {
        networksContent.innerHTML = '<p style="text-align: center; color: #6B7280;">No networks found</p>';
        return;
    }
    
    networksContent.innerHTML = networks.map(network => {
        const signalStrength = getSignalStrength(network.signal);
        const signalBars = createSignalBars(signalStrength);
        
        return `
            <div class="network-item" onclick="selectNetwork('${escapeHtml(network.ssid)}', '${network.encryption}')">
                <div class="network-info">
                    <div class="network-ssid">${escapeHtml(network.ssid)}</div>
                    <div class="network-details">
                        ${network.encryption} · Channel ${network.channel || '?'}
                    </div>
                </div>
                <div class="network-signal">
                    ${signalBars}
                    <span style="font-size: 0.85em; color: #6B7280;">${signalStrength}%</span>
                </div>
            </div>
        `;
    }).join('');
}

// Get signal strength percentage
function getSignalStrength(signal) {
    // Convert dBm to percentage (rough approximation)
    // -30 dBm = 100%, -90 dBm = 0%
    const percentage = Math.max(0, Math.min(100, ((signal + 90) / 60) * 100));
    return Math.round(percentage);
}

// Create signal bars HTML
function createSignalBars(percentage) {
    const bars = [20, 40, 60, 80, 100];
    return `
        <div class="signal-bars">
            ${bars.map((threshold, index) => `
                <div class="signal-bar ${percentage >= threshold ? 'active' : ''}" 
                     style="height: ${(index + 1) * 4}px;"></div>
            `).join('')}
        </div>
    `;
}

// Select network for configuration
function selectNetwork(ssid, encryption) {
    const configForm = document.getElementById('config-form');
    const configResult = document.getElementById('config-result');
    
    // Set form values
    document.getElementById('ssid').value = ssid;
    
    // Set encryption type
    const encryptionSelect = document.getElementById('encryption');
    if (encryption.includes('WPA2')) {
        encryptionSelect.value = 'WPA2-PSK';
    } else if (encryption.includes('WPA')) {
        encryptionSelect.value = 'WPA-PSK';
    } else {
        encryptionSelect.value = 'Open';
    }
    
    // Trigger encryption change event
    encryptionSelect.dispatchEvent(new Event('change'));
    
    // Show form, hide result
    configForm.style.display = 'block';
    configResult.style.display = 'none';
    
    // Scroll to form
    configForm.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// Configure WiFi
async function configureWiFi(event) {
    event.preventDefault();
    
    const form = event.target;
    const submitBtn = form.querySelector('button[type="submit"]');
    const configResult = document.getElementById('config-result');
    
    const ssid = document.getElementById('ssid').value;
    const password = document.getElementById('password').value;
    const encryption = document.getElementById('encryption').value;
    
    // Validation
    if (encryption !== 'Open' && password.length < 8) {
        showResult('Password must be at least 8 characters', 'error');
        return;
    }
    
    // Show loading state
    submitBtn.disabled = true;
    submitBtn.textContent = 'Connecting...';
    
    try {
        const response = await fetch('/api/configure', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                ssid: ssid,
                password: password,
                encryption: encryption
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            showResult(`Successfully configured WiFi: ${ssid}. Connecting...`, 'success');
            
            // Reload status after a few seconds
            setTimeout(() => {
                loadStatus();
                form.reset();
                document.getElementById('config-form').style.display = 'none';
            }, 3000);
        } else {
            showResult('Configuration failed: ' + data.error, 'error');
        }
    } catch (error) {
        console.error('Error configuring WiFi:', error);
        showResult('Error configuring WiFi. Please try again.', 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Connect';
    }
}

// Show configuration result
function showResult(message, type) {
    const configResult = document.getElementById('config-result');
    configResult.textContent = message;
    configResult.className = `config-result ${type}`;
    configResult.style.display = 'block';
}

// Cancel configuration
function cancelConfig() {
    document.getElementById('config-form').style.display = 'none';
    document.getElementById('config-result').style.display = 'none';
}

// Load QR codes
async function loadQRCodes() {
    try {
        const response = await fetch('/api/qr-data');
        const data = await response.json();
        
        if (data.success) {
            const qrHotspot = document.getElementById('qr-hotspot');
            const qrWebui = document.getElementById('qr-webui');
            
            qrHotspot.src = data.qr_codes.hotspot_wifi.image;
            qrHotspot.style.display = 'block';
            qrHotspot.previousElementSibling.style.display = 'none';
            
            qrWebui.src = data.qr_codes.webui.image;
            qrWebui.style.display = 'block';
            qrWebui.previousElementSibling.style.display = 'none';
        }
    } catch (error) {
        console.error('Error loading QR codes:', error);
    }
}

// Utility: Escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
