#!/bin/bash

MINECRAFT_DIR="$HOME/minecraft"
BACKUP_DIR="$MINECRAFT_DIR/backups"
TMP_DIR="/tmp/bedrock_update"
SERVICE="bedrock"

mkdir -p "$BACKUP_DIR" "$TMP_DIR"

echo "[INFO] Getting latest Bedrock server version from wiki..."

# Get the wiki page 
WIKI_PAGE=$(curl -s -A "Mozilla/5.0" "https://minecraft.wiki/w/Bedrock_Dedicated_Server")

if [[ -z "$WIKI_PAGE" ]]; then
  echo "[ERROR] Failed to download wiki page"
  exit 1
fi

echo "[DEBUG] Wiki page downloaded, size: $(echo "$WIKI_PAGE" | wc -c) characters"

# Look for the latest version in the infobox - specifically for "Release:" followed by version
echo "[DEBUG] Looking for 'Release:' pattern near 'Latest version'..."
VERSION=$(echo "$WIKI_PAGE" | grep -A 10 -B 10 "Latest version" | grep -o "Release:[[:space:]]*[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | sed 's/Release:[[:space:]]*//' | head -1)

if [[ -z "$VERSION" ]]; then
  echo "[DEBUG] Release pattern not found, looking for version links in infobox..."
  # Look specifically for Bedrock Edition version links in the infobox area
  VERSION=$(echo "$WIKI_PAGE" | grep -A 20 -B 5 "Latest version" | grep -o 'href="[^"]*Bedrock_Edition_[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+[^"]*"' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
fi

if [[ -z "$VERSION" ]]; then
  echo "[DEBUG] Version links failed, trying title attributes in infobox area..."
  # Look for title="1.21.93.1" in the Latest version section
  VERSION=$(echo "$WIKI_PAGE" | grep -A 20 -B 5 "Latest version" | grep -o 'title="[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"' | sed 's/title="//' | sed 's/"//' | head -1)
fi

if [[ -z "$VERSION" ]]; then
  echo "[DEBUG] Title pattern failed, trying valid Minecraft version patterns..."
  # Get version numbers that look like valid Minecraft versions (1.20-1.22 range)
  VERSION=$(echo "$WIKI_PAGE" | grep -o '1\.2[0-9]\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
fi

if [[ -z "$VERSION" ]]; then
  echo "[DEBUG] Minecraft range failed, trying broader but still reasonable range..."
  # Allow 1.16 to 1.30 range to be future-proof but avoid random numbers
  VERSION=$(echo "$WIKI_PAGE" | grep -o '1\.[1-3][0-9]\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
fi

if [[ -z "$VERSION" ]]; then
  echo "[ERROR] Could not extract version from wiki"
  exit 1
fi

echo "[INFO] Found version: $VERSION"

# Check if we already have this version
VERSION_FILE="$MINECRAFT_DIR/current_version.txt"
CURRENT_VERSION=""

if [[ -f "$VERSION_FILE" ]]; then
  CURRENT_VERSION=$(cat "$VERSION_FILE")
  echo "[INFO] Currently installed version: $CURRENT_VERSION"
else
  echo "[INFO] No version file found - this appears to be a fresh installation"
fi

# Compare versions
if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
  echo "[INFO] Server is already up to date (version $VERSION)"
  echo "[INFO] No update needed - exiting"
  exit 0
fi

echo "[INFO] Update available: $CURRENT_VERSION -> $VERSION"

# Build filename and URL
FILENAME="bedrock-server-${VERSION}.zip"
URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/$FILENAME"
ZIPPATH="$TMP_DIR/$FILENAME"

echo "[INFO] Downloading $URL"
if ! wget -q -O "$ZIPPATH" "$URL"; then
  echo "[ERROR] Download failed for version $VERSION"
  echo "[DEBUG] The version might not be available yet, or URL structure changed"
  exit 1
fi

# Verify download
if [[ ! -s "$ZIPPATH" ]]; then
  echo "[ERROR] Downloaded file is empty"
  exit 1
fi

echo "[INFO] Download successful ($(stat -c%s "$ZIPPATH") bytes)"

echo "[INFO] Stopping service"
sudo systemctl stop "$SERVICE"

echo "[INFO] Backing up worlds"
if [[ -d "$MINECRAFT_DIR/worlds" ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  tar -czf "$BACKUP_DIR/worlds-$ts.tar.gz" "$MINECRAFT_DIR/worlds"
  echo "[INFO] Backup created: worlds-$ts.tar.gz"
fi

echo "[INFO] Installing server version $VERSION"
unzip -o "$ZIPPATH" -d "$TMP_DIR/extracted"

if [[ ! -f "$TMP_DIR/extracted/bedrock_server" ]]; then
  echo "[ERROR] bedrock_server executable not found in download"
  exit 1
fi

cp -r "$TMP_DIR/extracted/"* "$MINECRAFT_DIR/"
chmod +x "$MINECRAFT_DIR/bedrock_server"

echo "[INFO] Starting service"
sudo systemctl start "$SERVICE"

# Verify service started
sleep 2
if systemctl is-active --quiet "$SERVICE"; then
  echo "[SUCCESS] Updated to version $VERSION and service is running"
  # Save the new version
  echo "$VERSION" > "$VERSION_FILE"
  echo "[INFO] Version $VERSION saved to $VERSION_FILE"
else
  echo "[WARN] Service may not have started properly"
  echo "[DEBUG] Check status with: sudo systemctl status $SERVICE"
fi

# Cleanup
rm -rf "$TMP_DIR"

echo "[INFO] Update complete! Players can now connect to the updated server."
