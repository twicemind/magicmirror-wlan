# Release Guide

Anleitung für das Erstellen und Veröffentlichen von Releases für MagicMirror WLAN Manager.

## Übersicht

Dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/):

```
MAJOR.MINOR.PATCH

MAJOR: Breaking Changes (inkompatibl)
MINOR: Neue Features (abwärtskompatibel)
PATCH: Bugfixes (abwärtskompatibel)
```

Beispiele:
- `1.0.0` → `1.0.1`: Bugfix
- `1.0.0` → `1.1.0`: Neues Feature
- `1.0.0` → `2.0.0`: Breaking Change

## Release-Prozess

### 1. Vorbereitung

Stelle sicher, dass:
- Alle Änderungen committed sind
- Alle Tests erfolgreich laufen
- Dokumentation aktualisiert ist

```bash
# Status prüfen
git status

# Lokale Tests durchführen
bash test/test-environment.sh
```

### 2. CHANGELOG.md aktualisieren

Bearbeite `CHANGELOG.md` und füge einen neuen Abschnitt hinzu:

```markdown
## [1.1.0] - 2026-04-20

### Added
- Neue Feature-Beschreibung

### Changed
- Geänderte Funktionalität

### Fixed
- Behobene Bugs

### Removed
- Entfernte Features
```

### 3. Release erstellen

Nutze das automatische Release-Script:

```bash
./create-release.sh 1.1.0
```

Das Script:
1. ✓ Validiert die Version
2. ✓ Aktualisiert VERSION Datei
3. ✓ Prüft CHANGELOG.md
4. ✓ Aktualisiert package.json
5. ✓ Erstellt Git Commit
6. ✓ Erstellt Git Tag

### 4. Push zu GitHub

```bash
# Commit und Tag pushen
git push
git push --tags

# Oder in einem Befehl
git push && git push --tags
```

### 5. GitHub Release erstellen

#### Option A: Über GitHub Web Interface

1. Gehe zu https://github.com/twicemind/magicmirror-wlan/releases/new
2. Wähle Tag: `v1.1.0`
3. Release Title: `v1.1.0 - Release Name`
4. Beschreibung aus CHANGELOG.md kopieren
5. "Publish release" klicken

#### Option B: Über GitHub CLI (gh)

```bash
# Release notes aus CHANGELOG.md extrahieren
# Und GitHub Release erstellen
gh release create v1.1.0 --title "v1.1.0 - Release Name" --notes-file <(sed -n '/^## \[1.1.0\]/,/^## \[/p' CHANGELOG.md | head -n -1)
```

### 6. Verifizierung

Teste die Installation mit dem neuen Release:

```bash
# Test via curl
curl -sSL https://raw.githubusercontent.com/twicemind/magicmirror-wlan/v1.1.0/install.sh | bash

# Oder via git
git clone --branch v1.1.0 https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan
sudo bash install.sh
```

## Manuelle Release-Erstellung

Falls du den Prozess manuell durchführen möchtest:

```bash
# 1. VERSION Datei aktualisieren
echo "1.1.0" > VERSION

# 2. CHANGELOG.md bearbeiten
nano CHANGELOG.md

# 3. package.json aktualisieren
nano magicmirror-module/MMM-WLANManager/package.json

# 4. Änderungen committen
git add VERSION CHANGELOG.md magicmirror-module/MMM-WLANManager/package.json
git commit -m "chore: Bump version to v1.1.0"

# 5. Tag erstellen
git tag -a v1.1.0 -m "Release version 1.1.0

Release Notes hier...
"

# 6. Push
git push && git push --tags
```

## Hotfix-Releases

Für dringende Bugfixes:

```bash
# Neuen Branch vom letzten Release
git checkout -b hotfix-1.0.1 v1.0.0

# Fixes implementieren
git add .
git commit -m "fix: Critical bug description"

# Release erstellen
./create-release.sh 1.0.1

# Merge zurück zu main
git checkout main
git merge hotfix-1.0.1

# Push
git push && git push --tags

# Branch löschen
git branch -d hotfix-1.0.1
```

## Pre-Releases / Beta-Versionen

Für Test-Releases:

```bash
# Beta-Version erstellen
echo "1.1.0-beta.1" > VERSION

git add VERSION
git commit -m "chore: Prepare v1.1.0-beta.1"

git tag -a v1.1.0-beta.1 -m "Beta Release v1.1.0-beta.1"

git push && git push --tags
```

Im GitHub Release als "Pre-release" markieren.

## Release-Checkliste

Vor jedem Release:

- [ ] Alle Tests bestanden
- [ ] Dokumentation aktualisiert (README, INSTALLATION, etc.)
- [ ] CHANGELOG.md vollständig
- [ ] Breaking Changes dokumentiert
- [ ] Migration Guide (falls nötig)
- [ ] VERSION Datei aktualisiert
- [ ] package.json aktualisiert
- [ ] Alle Commits gepusht
- [ ] Tag erstellt und gepusht
- [ ] GitHub Release veröffentlicht
- [ ] Installation getestet

## Rollback

Falls ein Release Probleme hat:

```bash
# Tag lokal löschen
git tag -d v1.1.0

# Tag remote löschen
git push --delete origin v1.1.0

# GitHub Release löschen (via Web Interface oder gh CLI)
gh release delete v1.1.0

# Commit zurücksetzen (wenn nötig)
git reset --hard HEAD^
git push --force
```

## Versionierungs-Beispiele

### Patch Release (1.0.0 → 1.0.1)

```markdown
## [1.0.1] - 2026-04-20

### Fixed
- Fixed WiFi scan hanging on some systems
- Corrected QR code encoding for special characters
- Fixed service restart on configuration change
```

### Minor Release (1.0.0 → 1.1.0)

```markdown
## [1.1.0] - 2026-04-25

### Added
- Multiple WiFi configuration support (failover)
- Ethernet detection (auto-disable HotSpot)
- HTTPS support for WebUI
- Advanced logging options

### Improved
- Faster network scanning
- Better error messages in WebUI
```

### Major Release (1.0.0 → 2.0.0)

```markdown
## [2.0.0] - 2026-05-01

### Breaking Changes
- Minimum Python version: 3.10 (was 3.9)
- Changed API endpoint: `/api/configure` → `/api/wifi/configure`
- New configuration file format

### Migration Guide
See MIGRATION_2.0.md for upgrade instructions.

### Added
- Complete API rewrite with better error handling
- New database backend for WiFi configurations
- Mobile app support
```

## Changelog-Kategorien

Verwende diese Standard-Kategorien in CHANGELOG.md:

- **Added**: Neue Features
- **Changed**: Änderungen an bestehenden Features
- **Deprecated**: Bald zu entfernende Features
- **Removed**: Entfernte Features
- **Fixed**: Bugfixes
- **Security**: Sicherheits-Updates
- **Improved**: Verbesserungen an bestehenden Features
- **Breaking Changes**: Inkompatible Änderungen

## Nützliche Git-Befehle

```bash
# Alle Tags anzeigen
git tag -l

# Tag-Details anzeigen
git show v1.0.0

# Letzten Tag anzeigen
git describe --tags --abbrev=0

# Änderungen seit Tag
git log v1.0.0..HEAD --oneline

# Alle Releases anzeigen
git tag -l -n9

# Lokalen Tag zu Remote pushen
git push origin v1.0.0

# Alle Tags pushen
git push --tags
```

## GitHub Release Features

Nutze diese Features in GitHub Releases:

- **Release Notes**: Aus CHANGELOG.md kopieren
- **Assets**: Optional install.sh oder ZIP hochladen
- **Pre-release**: Für Beta-Versionen markieren
- **Latest**: Automatisch für neueste Stable-Version
- **Discussion**: Release-spezifische Diskussionen aktivieren

## Support nach Release

Nach einem Release:

1. **Monitor Issues**: Achte auf Bug-Reports
2. **Update Documentation**: Webseite/Wiki aktualisieren
3. **Announce**: In relevant Foren/Channels posten
4. **Monitor Metrics**: Download-Zahlen, Feedback sammeln

## Automatisierung (Future)

Mögliche GitHub Actions für automatische Releases:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body_path: CHANGELOG.md
```

---

**Nächster Release**: TBD  
**Aktueller Release**: v1.0.0  
**Branch Policy**: main = stable, develop = development
