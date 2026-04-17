# GitHub Actions Workflows

Dieses Verzeichnis enthält die GitHub Actions Workflows für automatische Tests und Releases.

## Workflows

### 1. test.yml - Continuous Integration

**Trigger:** Push auf `main` oder `develop`, Pull Requests

**Jobs:**
- **shellcheck**: Linting aller Bash-Scripts
- **python-validation**: Python-Code Formatierung und Syntax-Checks
- **config-validation**: Validierung der Config-Templates
- **service-validation**: Systemd Service Files Prüfung
- **magicmirror-module**: Node.js Module Validation
- **integration-test**: Mock-Mode Tests für WebUI und Network Monitor
- **documentation**: Markdown Linting und Dokumentations-Check

**Verwendete Tools:**
- ShellCheck für Bash
- Black, flake8, pylint für Python
- Node.js für MagicMirror Modul
- markdownlint für Dokumentation

### 2. release.yml - Manual Release

**Trigger:** 
- Push eines Tags (z.B. `v1.0.0`)
- Manueller Workflow Dispatch

**Ablauf:**
1. Checkout Code
2. Version aus Tag oder Input extrahieren
3. Release Archive erstellen (.tar.gz)
4. SHA256 Checksums generieren
5. Changelog aus CHANGELOG.md extrahieren
6. Release Notes generieren
7. GitHub Release erstellen mit Artifacts

**Artifacts:**
- `magicmirror-wlan-{version}.tar.gz` - Installationsarchiv
- `checksums.txt` - SHA256 Prüfsummen

**Manueller Trigger:**
```bash
# Via GitHub Web Interface:
# Actions → Create Release → Run workflow → Enter version

# Via GitHub CLI:
gh workflow run release.yml -f version=1.0.1
```

### 3. auto-release.yml - Automatic Release

**Trigger:** Push auf `main` Branch (außer Markdown-Dateien)

**Semantic Versioning:**
- `BREAKING CHANGE:`, `feat!:`, `fix!:` → **Major** Version (X.0.0)
- `feat:` → **Minor** Version (0.X.0)
- `fix:`, `chore:`, etc. → **Patch** Version (0.0.X)

**Ablauf:**
1. Tests ausführen (ShellCheck, Python Syntax)
2. Letzten Tag ermitteln
3. Commit-Messages analysieren
4. Neuen Version-Bump berechnen
5. VERSION Datei aktualisieren
6. package.json aktualisieren
7. CHANGELOG.md aktualisieren
8. Commit und Tag erstellen
9. Push zu Repository
10. GitHub Release erstellen

**Commit Message Convention:**
```bash
feat: Add new feature          # → Minor bump (1.0.0 → 1.1.0)
fix: Fix bug                   # → Patch bump (1.0.0 → 1.0.1)
feat!: Breaking change         # → Major bump (1.0.0 → 2.0.0)
chore: Update dependencies     # → Patch bump (1.0.0 → 1.0.1)
```

## Workflow-Dateien

```
.github/workflows/
├── test.yml           # CI Tests bei jedem Push/PR
├── release.yml        # Manuelle Releases
└── auto-release.yml   # Automatische Releases
```

## Verwendung

### Entwicklungs-Workflow

1. **Feature entwickeln:**
   ```bash
   git checkout -b feature/my-feature
   # ... Code ändern ...
   git commit -m "feat: Add awesome feature"
   git push
   ```

2. **Pull Request erstellen:**
   - Tests laufen automatisch
   - Bei grünem Build: Merge zu `main`

3. **Nach Merge zu main:**
   - Auto-Release läuft automatisch
   - Neue Version wird basierend auf Commits berechnet
   - Release wird automatisch erstellt

### Manueller Release

```bash
# 1. create-release.sh nutzen
./create-release.sh 1.2.0

# 2. Push Tag
git push --tags

# 3. GitHub Actions erstellt automatisch Release
```

### Hotfix-Release

```bash
# 1. Von letztem Release-Tag branchen
git checkout -b hotfix-1.0.1 v1.0.0

# 2. Fix implementieren
git commit -m "fix: Critical bug"

# 3. Release erstellen
./create-release.sh 1.0.1
git push --tags

# 4. Zurück mergen
git checkout main
git merge hotfix-1.0.1
git push
```

## Secrets & Permissions

**Benötigte Permissions:**
- `contents: write` - Für Release-Erstellung
- `GITHUB_TOKEN` - Automatisch verfügbar

**Keine zusätzlichen Secrets erforderlich**

## Badges

Füge diese Badges zu README.md hinzu:

```markdown
[![Tests](https://github.com/twicemind/magicmirror-wlan/actions/workflows/test.yml/badge.svg)](https://github.com/twicemind/magicmirror-wlan/actions/workflows/test.yml)
[![Release](https://github.com/twicemind/magicmirror-wlan/actions/workflows/release.yml/badge.svg)](https://github.com/twicemind/magicmirror-wlan/actions/workflows/release.yml)
```

## Debugging

### Logs anzeigen

```bash
# Via GitHub CLI
gh run list --workflow=test.yml
gh run view <run-id> --log

# Via Web Interface
https://github.com/twicemind/magicmirror-wlan/actions
```

### Workflow lokal testen

```bash
# Mit act (https://github.com/nektos/act)
act -j shellcheck
act -j python-validation
```

### Häufige Probleme

**Problem:** ShellCheck Fehler
```bash
# Lokal testen
shellcheck install.sh
shellcheck scripts/*.sh
```

**Problem:** Python Syntax Fehler
```bash
# Lokal testen
python -m py_compile webui/app.py
black --check webui/app.py
```

**Problem:** Auto-Release erstellt keinen Release
- **Grund:** Keine Commits seit letztem Tag
- **Lösung:** Mind. 1 Commit seit letztem Release nötig

## Workflow-Anpassungen

### Tests deaktivieren

Temporär einen Workflow deaktivieren:
1. GitHub → Actions → Workflow auswählen → "..." → Disable workflow

### Workflow überspringen

Commit Message mit `[skip ci]`:
```bash
git commit -m "docs: Update README [skip ci]"
```

### Trigger ändern

In Workflow-Datei `on:` Section anpassen:
```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - '**.py'
      - '**.sh'
```

## Best Practices

1. **Conventional Commits** nutzen für Auto-Versioning
2. **Tests** vor Merge sicherstellen (grüner Build)
3. **CHANGELOG.md** manuell pflegen für wichtige Releases
4. **Tags** nicht löschen (Breaking für Installationen)
5. **Hotfixes** zurück in main mergen

## Monitoring

- **Test-Status:** https://github.com/twicemind/magicmirror-wlan/actions/workflows/test.yml
- **Release-Status:** https://github.com/twicemind/magicmirror-wlan/actions/workflows/release.yml
- **Auto-Release-Status:** https://github.com/twicemind/magicmirror-wlan/actions/workflows/auto-release.yml

## Weitere Ressourcen

- [GitHub Actions Dokumentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
