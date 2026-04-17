# MMM-WLANManager

MagicMirror² module that displays QR codes for WiFi HotSpot connection and WebUI access when no internet is available.

## Features

- 🔍 Automatic detection of internet connectivity
- 📱 QR codes for easy mobile setup
- 🔄 Auto-hide when internet connection is established
- 🎨 Beautiful fullscreen display on separate page

## Installation

### Automatic (as part of magicmirror-wlan)

This module is automatically installed when you install the magicmirror-wlan project.

### Manual Installation

```bash
cd ~/MagicMirror/modules
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan/magicmirror-module/MMM-WLANManager
npm install
```

## Configuration

Add the module to your `config/config.js`:

```javascript
{
    module: "MMM-WLANManager",
    position: "fullscreen_below", // Shows on separate page
    config: {
        updateInterval: 30000,      // Check every 30 seconds
        apiUrl: "http://localhost:8765",  // WebUI API URL
        showWhenOnline: false,      // Hide when internet is available
    }
}
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `updateInterval` | `30000` | How often to check network status (milliseconds) |
| `apiUrl` | `"http://localhost:8765"` | URL of the WLAN WebUI API |
| `showWhenOnline` | `false` | Whether to show module when internet is available |
| `animationSpeed` | `1000` | Animation speed when showing/hiding (milliseconds) |

## MagicMirror Pages Configuration

To use this module on a separate page, configure MagicMirror pages in your `config.js`:

```javascript
var config = {
    // ... other config ...
    
    modules: [
        // Page 0 (default) - Normal MagicMirror modules
        {
            module: "clock",
            position: "top_left",
            classes: "page0"
        },
        {
            module: "weather",
            position: "top_right",
            classes: "page0"
        },
        
        // Page 1 - WiFi Setup
        {
            module: "MMM-WLANManager",
            position: "fullscreen_below",
            classes: "page1"
        },
        
        // Page rotation module
        {
            module: "MMM-pages",
            config: {
                modules: [
                    ["clock", "weather"],  // Page 0
                    ["MMM-WLANManager"]    // Page 1
                ],
                fixed: []
            }
        }
    ]
};
```

## How It Works

1. **Network Monitor** checks internet connectivity every 30 seconds
2. If **no internet**: 
   - HotSpot starts automatically
   - MMM-WLANManager shows QR codes
   - Page automatically switches to WiFi setup view
3. User scans QR codes with phone to:
   - Connect to HotSpot WiFi
   - Open WebUI for configuration
4. When **internet connection established**:
   - Module hides automatically
   - Page switches back to normal view
   - HotSpot stops

## QR Codes

The module displays two QR codes:

1. **HotSpot WiFi Connection**
   - Format: `WIFI:T:WPA;S:MagicMirror-Setup;P:magicmirror;;`
   - Directly connects phone to HotSpot WiFi
   
2. **WebUI Access**
   - URL: `http://192.168.4.1:8765`
   - Opens configuration interface

## Screenshots

### HotSpot Active View
Shows QR codes and instructions for WiFi setup.

### Online View
Module is hidden when internet connection is available.

## Dependencies

- `axios` - HTTP client for API calls

## Troubleshooting

### Module doesn't show
- Check that `wlan-webui.service` is running
- Verify API URL in config matches WebUI port
- Check browser console for errors

### QR codes not loading
- Ensure WebUI API is accessible
- Check network status: `curl http://localhost:8765/api/qr-data`

### Module doesn't hide when online
- Set `showWhenOnline: false` in config
- Check network-monitor service status

## Development

### Testing Locally

```bash
# Set mock mode
export MOCK_MODE=true

# Start WebUI in test mode
cd webui
python3 app.py
```

## License

MIT License - see LICENSE file

## Author

twicemind

## Links

- [GitHub Repository](https://github.com/twicemind/magicmirror-wlan)
- [MagicMirror² Documentation](https://docs.magicmirror.builders/)
