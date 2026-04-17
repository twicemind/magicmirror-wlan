# MagicMirror WLAN Manager - Project Overview

## Projektbeschreibung

Automatisches WLAN-Management für MagicMirror auf Raspberry Pi mit folgenden Kernfunktionen:

1. **Automatischer HotSpot**: Wird aktiviert wenn kein WLAN konfiguriert ist ODER kein Internet verfügbar ist
2. **WebUI**: Webinterface zur WLAN-Konfiguration (Netzwerk auswählen, Passwort eingeben)
3. **MagicMirror-Modul**: Zeigt QR-Codes für HotSpot-Verbindung und WebUI-Zugriff an
4. **Auto-Hide**: Modul verschwindet automatisch wenn Internet-Verbindung besteht

## Architektur

```
┌─────────────────────────────────────────────────────────────┐
│                      Raspberry Pi                            │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │        Network Monitor Service                 │         │
│  │  - Prüft Internet-Konnektivität alle 30s       │         │
│  │  - Startet/Stoppt HotSpot automatisch          │         │
│  └────────────────────────────────────────────────┘         │
│                      │                                       │
│           ┌──────────┴──────────┐                           │
│           ▼                     ▼                            │
│  ┌─────────────────┐   ┌─────────────────┐                 │
│  │   HotSpot Mode  │   │  Client Mode    │                 │
│  │  (hostapd +     │   │  (wpa_supplicant│                 │
│  │   dnsmasq)      │   │   + dhcpcd)     │                 │
│  └─────────────────┘   └─────────────────┘                 │
│           │                     │                            │
│           ▼                     ▼                            │
│  ┌──────────────────────────────────────────┐               │
│  │         WebUI (Flask)                     │               │
│  │  - WLAN Scanner (iwlist/nmcli)           │               │
│  │  - WLAN Konfiguration                    │               │
│  │  - Status-API für MagicMirror            │               │
│  │  Port: 8765                              │               │
│  └──────────────────────────────────────────┘               │
│           │                                                  │
│           ▼                                                  │
│  ┌──────────────────────────────────────────┐               │
│  │   MagicMirror Module                     │               │
│  │   MMM-WLANManager                        │               │
│  │  - Zeigt QR-Codes wenn kein Internet     │               │
│  │  - QR1: HotSpot WLAN (SSID + Passwort)   │               │
│  │  - QR2: WebUI URL (http://192.168.4.1)   │               │
│  │  - Auto-Hide bei Internet-Verbindung     │               │
│  └──────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## Komponenten

### 1. Network Monitor (`network-monitor.service`)
- **Zweck**: Überwacht Netzwerk-Status und steuert HotSpot
- **Technologie**: Python-Script als systemd-Service
- **Funktionen**:
  - Prüft Internet-Konnektivität (ping 8.8.8.8, 1.1.1.1)
  - Aktiviert HotSpot wenn keine Verbindung
  - Deaktiviert HotSpot wenn WLAN erfolgreich
  - Status-API für andere Komponenten

### 2. HotSpot Manager
- **Technologie**: hostapd + dnsmasq
- **Konfiguration**:
  - SSID: `MagicMirror-Setup`
  - Passwort: `magicmirror` (oder generiert)
  - IP-Range: 192.168.4.0/24
  - Gateway: 192.168.4.1
  - Interface: wlan0 (oder configurierbar)

### 3. WebUI (`wlan-webui.service`)
- **Technologie**: Flask + Vanilla JavaScript
- **Port**: 8765
- **Features**:
  - WLAN-Scanner (verfügbare Netzwerke)
  - WLAN-Konfiguration (SSID, Passwort, Verschlüsselung)
  - Status-Dashboard
  - API-Endpoints für MagicMirror-Modul
- **API-Endpoints**:
  - `GET /api/status` - Netzwerk-Status
  - `GET /api/networks` - Verfügbare WLANs
  - `POST /api/configure` - WLAN konfigurieren
  - `GET /api/qr-data` - Daten für QR-Codes

### 4. MagicMirror-Modul (`MMM-WLANManager`)
- **Typ**: MagicMirror² Modul
- **Position**: fullscreen_below (eigene Seite)
- **Features**:
  - QR-Code für HotSpot-WLAN
  - QR-Code für WebUI-URL
  - Anleitung für Nutzer
  - Auto-Hide bei Internet-Verbindung
  - Rotation zu dieser Seite bei fehlendem Internet

## Projektstruktur

```
magicmirror-wlan/
├── README.md                      # Haupt-Dokumentation
├── PROJECT_OVERVIEW.md            # Diese Datei
├── INSTALLATION.md                # Installations-Anleitung
├── LICENSE                        # MIT Lizenz
├── VERSION                        # Version (1.0.0)
├── install.sh                     # Haupt-Installationsskript
├── uninstall.sh                   # Deinstallation
│
├── services/                      # Systemd Services
│   ├── network-monitor.service    # Network Monitor Service
│   ├── wlan-webui.service         # WebUI Service
│   └── hotspot-setup.service      # HotSpot Setup (oneshot)
│
├── scripts/                       # Helper Scripts
│   ├── network-monitor.py         # Netzwerk-Überwachung
│   ├── start-hotspot.sh           # HotSpot starten
│   ├── stop-hotspot.sh            # HotSpot stoppen
│   ├── configure-wlan.sh          # WLAN konfigurieren
│   ├── check-internet.sh          # Internet-Check
│   └── generate-qr.sh             # QR-Code generieren
│
├── webui/                         # WebUI für WLAN-Konfiguration
│   ├── app.py                     # Flask Application
│   ├── requirements.txt           # Python Dependencies
│   ├── templates/
│   │   └── index.html             # WebUI Interface
│   ├── static/
│   │   ├── style.css              # CSS
│   │   └── script.js              # JavaScript
│   └── config.json                # WebUI Konfiguration
│
├── magicmirror-module/            # MagicMirror Modul
│   └── MMM-WLANManager/
│       ├── MMM-WLANManager.js     # Modul-Code
│       ├── MMM-WLANManager.css    # Styling
│       ├── node_helper.js         # Backend (API-Calls)
│       └── README.md              # Modul-Dokumentation
│
├── config/                        # Konfigurationsdateien
│   ├── hostapd.conf.template      # HotSpot-Konfiguration
│   ├── dnsmasq.conf.template      # DHCP-Server
│   └── wpa_supplicant.conf.template
│
├── test/                          # Test-Umgebung
│   ├── test-environment.sh        # Lokale Test-Sandbox starten
│   ├── mock-network.py            # Mock für Netzwerk-Funktionen
│   ├── test-webui.sh              # WebUI Tests
│   └── README.md                  # Test-Dokumentation
│
└── docs/                          # Erweiterte Dokumentation
    ├── API.md                     # API-Dokumentation
    ├── TESTING.md                 # Test-Anleitung
    └── TROUBLESHOOTING.md         # Fehlerbehebung
```

## Ablauf-Diagramm

```
┌─────────────────┐
│  System Start   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Network Monitor startet │
└────────┬────────────────┘
         │
         ▼
┌──────────────────────┐
│ Prüfe Internet       │<──────────┐
│ (ping 8.8.8.8)       │           │
└────────┬─────────────┘           │
         │                         │
    ┌────┴────┐                    │
    │         │                    │
    ▼         ▼                    │
┌────────┐ ┌──────────┐            │
│Internet│ │   Kein   │            │
│  OK    │ │ Internet │            │
└───┬────┘ └────┬─────┘            │
    │           │                  │
    │           ▼                  │
    │      ┌──────────────┐        │
    │      │Start HotSpot │        │
    │      │+ WebUI       │        │
    │      └──────┬───────┘        │
    │             │                │
    │             ▼                │
    │      ┌────────────────────┐  │
    │      │MagicMirror zeigt   │  │
    │      │QR-Codes (Page 1)   │  │
    │      └──────┬─────────────┘  │
    │             │                │
    │             ▼                │
    │      ┌────────────────────┐  │
    │      │User verbindet      │  │
    │      │Handy mit HotSpot   │  │
    │      └──────┬─────────────┘  │
    │             │                │
    │             ▼                │
    │      ┌────────────────────┐  │
    │      │User konfiguriert   │  │
    │      │WLAN über WebUI     │  │
    │      └──────┬─────────────┘  │
    │             │                │
    │             ▼                │
    │      ┌────────────────────┐  │
    │      │Pi verbindet zu     │  │
    │      │echtem WLAN         │  │
    │      └──────┬─────────────┘  │
    │             │                │
    ▼             ▼                │
┌────────────────────────┐         │
│Stop HotSpot            │         │
│MagicMirror: Normal View│         │
└────────┬───────────────┘         │
         │                         │
         │  Wait 30 Sekunden       │
         └─────────────────────────┘
```

## Technologie-Stack

- **Backend**: Python 3.9+ (Flask)
- **Frontend**: Vanilla JavaScript + CSS
- **Netzwerk**: hostapd, dnsmasq, wpa_supplicant
- **MagicMirror**: Node.js Modul
- **Services**: systemd
- **QR-Codes**: qrencode
- **Testing**: Python unittest, Mock-Objekte

## Abhängigkeiten

### Raspberry Pi (Produktiv)
- hostapd
- dnsmasq
- wpa_supplicant
- Python 3.9+
- Flask
- qrencode
- wireless-tools
- net-tools

### Entwicklung (Lokal)
- Python 3.9+
- Docker (optional für Test-Umgebung)
- Node.js (für MagicMirror-Modul-Tests)

## Installation

```bash
# Via Git
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan
sudo bash install.sh

# Via Curl (ein-Zeilen-Installation)
curl -sSL https://raw.githubusercontent.com/twicemind/magicmirror-wlan/main/install.sh | sudo bash
```

## Testing

Vollständig lokal testbar ohne echten Raspberry Pi:

```bash
# Test-Umgebung starten
bash test/test-environment.sh

# WebUI testen
cd webui
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py --mock-mode
```

## Integration mit magicmirror-setup

Dieses Projekt ist eigenständig, kann aber später in `magicmirror-setup` integriert werden:

```bash
# In magicmirror-setup/install.sh
INSTALL_WLAN_MANAGER=true bash install.sh
```

## Roadmap

### Version 1.0.0 (MVP)
- [x] Projekt-Architektur
- [ ] Network Monitor Service
- [ ] HotSpot Manager (hostapd + dnsmasq)
- [ ] WebUI (WLAN-Scanner + Konfiguration)
- [ ] MagicMirror-Modul (QR-Codes)
- [ ] Installation-Scripts
- [ ] Test-Sandbox
- [ ] Vollständige Dokumentation

### Version 1.1.0 (Advanced Features)
- [ ] Mehrfach-WLAN-Konfiguration (Failover)
- [ ] Ethernet-Erkennung (kein HotSpot bei LAN-Verbindung)
- [ ] Erweiterte Sicherheit (HTTPS für WebUI)
- [ ] Logging und Monitoring

### Version 1.2.0 (Integration)
- [ ] Integration in magicmirror-setup
- [ ] Auto-Update Mechanismus
- [ ] WebUI in magicmirror-setup WebUI integrieren

## Lizenz

MIT License - siehe LICENSE Datei
