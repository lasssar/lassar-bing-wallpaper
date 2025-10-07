#!/bin/bash
# lassar-bing-wallpaper.sh
# Universal Bing daily wallpaper fetcher for Linux
# Author: Lassar Kardival
# License: MIT
# Year: 2025

BING_URL="https://www.bing.com"
DAY=$(shuf -i 0-7 -n 1)
API="$BING_URL/HPImageArchive.aspx?format=js&idx=$DAY&n=1&mkt=en-US"

PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/BingWallpapers"
mkdir -p "$PICTURES_DIR"

API_RESPONSE=$(curl -A "Mozilla/5.0" -s "$API")
URLBASE=$(echo "$API_RESPONSE" | grep -oP '(?<="urlbase":")[^"]+')

IMG_URL="$BING_URL${URLBASE}_UHD.jpg"
if ! curl -A "Mozilla/5.0" -s --head --fail "$IMG_URL" >/dev/null; then
    IMG_URL="$BING_URL${URLBASE}_1920x1080.jpg"
fi

IMG_NAME="${IMG_URL##*/}"
IMG_PATH="$PICTURES_DIR/$IMG_NAME"
curl -A "Mozilla/5.0" -s -o "$IMG_PATH" "$IMG_URL"

# Delete images older than 7 days
find "$PICTURES_DIR" -type f -mtime +7 -name "*.jpg" -delete 2>/dev/null

# Set wallpaper
if command -v nitrogen >/dev/null 2>&1; then
    nitrogen --set-auto "$IMG_PATH" --save
elif command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$IMG_PATH"
elif command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.background picture-uri "file://$IMG_PATH"
fi

# Notification
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Lassar Bing Wallpaper" "New Bing wallpaper applied: $IMG_NAME"
fi

echo "✅ New Bing wallpaper saved to $IMG_PATH"
