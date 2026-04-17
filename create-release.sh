#!/bin/bash
#
# Create Release for MagicMirror WLAN Manager
#
# Usage: ./create-release.sh <version>
# Example: ./create-release.sh 1.0.0

set -e

VERSION="$1"

if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

# Validate version format (semantic versioning)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

echo "=================================="
echo "Creating Release v$VERSION"
echo "=================================="
echo ""

# Check if we're in the right directory
if [[ ! -f "VERSION" ]] || [[ ! -f "CHANGELOG.md" ]]; then
    echo "Error: Must be run from project root (VERSION and CHANGELOG.md not found)"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: There are uncommitted changes. Commit or stash them first."
    git status --short
    exit 1
fi

# Update VERSION file
echo "Updating VERSION file to $VERSION..."
echo "$VERSION" > VERSION

# Verify CHANGELOG.md has entry for this version
if ! grep -q "## \[$VERSION\]" CHANGELOG.md; then
    echo ""
    echo "⚠️  Warning: CHANGELOG.md does not have an entry for version $VERSION"
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled. Please update CHANGELOG.md first."
        exit 1
    fi
fi

# Update package.json version in MagicMirror module
if [[ -f "magicmirror-module/MMM-WLANManager/package.json" ]]; then
    echo "Updating package.json version..."
    sed -i.bak "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" magicmirror-module/MMM-WLANManager/package.json
    rm magicmirror-module/MMM-WLANManager/package.json.bak
fi

# Git commit
echo ""
echo "Creating git commit..."
git add VERSION CHANGELOG.md magicmirror-module/MMM-WLANManager/package.json
git commit -m "chore: Bump version to v$VERSION"

# Create git tag
echo "Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION

See CHANGELOG.md for details."

echo ""
echo "=================================="
echo "✓ Release v$VERSION created!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Push commit and tag:"
echo "   git push && git push --tags"
echo ""
echo "2. Create GitHub Release:"
echo "   - Go to: https://github.com/twicemind/magicmirror-wlan/releases/new"
echo "   - Select tag: v$VERSION"
echo "   - Copy release notes from CHANGELOG.md"
echo "   - Publish release"
echo ""
echo "3. Test installation:"
echo "   curl -sSL https://raw.githubusercontent.com/twicemind/magicmirror-wlan/v$VERSION/install.sh | sudo bash"
echo ""
