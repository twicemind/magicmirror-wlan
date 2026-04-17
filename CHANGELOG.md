# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

## [1.0.0] - 2026-04-17

### Added
- **🎉 Initial Release** - MagicMirror WLAN Manager v1.0.0

#### Core Features
- **Automatischer HotSpot**: Startet automatisch wenn kein Internet verfügbar ist
  - SSID: `MagicMirror-Setup`
  - Passwort: `magicmirror`
  - IP-Range: 192.168.4.0/24
  - Basierend auf hostapd + dnsmasq
- **Network Monitor Service**: Python-basierter systemd Service
  - Prüft Internet-Konnektivität alle 30 Sekunden
  - Automatisches Umschalten zwischen HotSpot und Client Mode
  - Status-API für andere Komponenten
- **WebUI für WiFi-Konfiguration** (Port 8765):
  - WiFi-Scanner mit Signal-Stärke-Anzeige
  - Network-Auswahl und Passwort-Eingabe
  - Support für WPA2, WPA und Open Networks
  - Status-Dashboard mit Live-Updates
  - QR-Code-Generierung
  - Responsive Design für Desktop und Mobile
- **MagicMirror-Modul** (MMM-WLANManager):
  - Zeigt QR-Codes für HotSpot und WebUI
  - Auto-Show bei fehlendem Internet
  - Auto-Hide bei bestehender Verbindung
  - Fullscreen-Ansicht auf separater Page
  - Setup-Anleitung mit Schritt-für-Schritt-Guide

#### Installation & Deployment
- **Automatische Installation**: `install.sh` für Raspberry Pi
  - Installiert alle Abhängigkeiten (hostapd, dnsmasq, Python)
  - Richtet Python Virtual Environment ein
  - Konfiguriert systemd Services
  - Setzt Berechtigungen (sudoers)
  - Installiert MagicMirror-Modul optional
- **Deinstallation**: `uninstall.sh` für sauberes Entfernen
- **Systemd Services**:
  - `network-monitor.service` - Netzwerk-Überwachung
  - `wlan-webui.service` - WebUI Server

#### Scripts & Tools
- `network-monitor.py` - Network monitoring und HotSpot-Steuerung
- `start-hotspot.sh` - HotSpot starten (hostapd + dnsmasq)
- `stop-hotspot.sh` - HotSpot stoppen, WLAN Client aktivieren
- `configure-wlan.sh` - WLAN in wpa_supplicant konfigurieren
- `check-internet.sh` - Internet-Konnektivität prüfen

#### Testing & Development
- **Vollständig lokal testbar**: Mock-Mode für alle Komponenten
- **Test-Environment**: `test-environment.sh` startet lokale Sandbox
  - Mock-Dateien für Internet-Status und HotSpot-Status
  - WebUI auf localhost:8765
  - Keine root-Rechte oder echte Netzwerk-Änderungen nötig
- **Mock-Funktionen**:
  - Mock Internet-Status (`mock-internet.txt`)
  - Mock HotSpot-Status (`mock-hotspot-active.txt`)
  - Mock WLAN-Scanner (Test-Netzwerke)
  - Mock wpa_supplicant Konfiguration

#### Documentation
- **README.md**: Komplette Projekt-Übersicht mit Features und Quick Start
- **PROJECT_OVERVIEW.md**: Detaillierte Architektur-Dokumentation
  - Komponenten-Diagramme
  - Ablauf-Diagramme
  - Technologie-Stack
  - Projekt-Struktur
- **INSTALLATION.md**: Schritt-für-Schritt Installations-Anleitung
  - Automatische Installation
  - Manuelle Installation
  - MagicMirror-Konfiguration
  - Troubleshooting
- **QUICKSTART.md**: 5-Minuten Setup-Guide
- **test/README.md**: Umfangreicher Test-Guide
  - Test-Szenarien
  - Mock-File-Dokumentation
  - API-Tests
  - Integration-Tests
- **magicmirror-module/MMM-WLANManager/README.md**: Modul-Dokumentation
  - Installation
  - Konfiguration
  - API-Integration
  - Troubleshooting

#### API Endpoints
- `GET /api/status` - Netzwerk-Status abrufen
- `GET /api/networks` - Verfügbare WiFi-Netzwerke scannen
- `POST /api/configure` - WiFi konfigurieren
- `GET /api/qr-data` - QR-Code-Daten und Bilder
- `GET /health` - Health-Check

#### Configuration Templates
- `config/hostapd.conf.template` - HotSpot WiFi-Konfiguration
- `config/dnsmasq.conf.template` - DHCP/DNS-Server-Konfiguration
- `config/wpa_supplicant.conf.template` - WLAN-Client-Konfiguration

#### Features im Detail
- **QR-Code-Generierung**:
  - WiFi QR-Code im Format `WIFI:T:WPA;S:ssid;P:password;;`
  - WebUI URL QR-Code
  - Base64-encoded PNG-Bilder
- **Responsive WebUI**:
  - Mobile-optimiert
  - Touch-freundliche Buttons
  - Signal-Stärke-Visualisierung mit Bars
  - Live-Status-Updates alle 10 Sekunden
- **Sicherheit**:
  - Sudoers-Konfiguration nur für spezifische Scripts
  - User-basierte Services (nicht root)
  - Passwort-Validierung (min. 8 Zeichen)
- **Zuverlässigkeit**:
  - Automatische Service-Restarts bei Fehlern
  - Mehrfache DNS-Server für Internet-Checks
  - Timeout-Handling für alle Netzwerk-Operationen

### Technical Details
- **Backend**: Python 3.9+ mit Flask
- **Frontend**: Vanilla JavaScript + CSS (keine Dependencies)
- **Network**: hostapd, dnsmasq, wpa_supplicant
- **QR Codes**: qrencode + Python qrcode library
- **Services**: systemd
- **Platform**: Raspberry Pi 3/4/5 mit Raspberry Pi OS

### Dependencies
- hostapd
- dnsmasq
- wpa_supplicant
- Python 3.9+
- Flask 3.0.0
- qrcode[pil] 7.4.2
- Pillow 10.1.0
- wireless-tools
- net-tools

---

## Release Notes

### Wie man upgradet

```bash
cd /opt/magicmirror-wlan
sudo git pull
sudo systemctl restart network-monitor wlan-webui
```

### Breaking Changes
- Keine (Initial Release)

### Known Issues
- Keine bekannten Issues

### Roadmap für v1.1.0
- Multiple WiFi Konfigurationen (Failover)
- Ethernet-Erkennung (kein HotSpot bei LAN)
- HTTPS Support für WebUI
- Erweiterte Logging-Funktionen

---

[Unreleased]: https://github.com/twicemind/magicmirror-wlan/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/twicemind/magicmirror-wlan/releases/tag/v1.0.0
