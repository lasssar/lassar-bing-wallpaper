#!/bin/bash
# Updated 2025 version — Bing daily wallpaper setter
# Author: Laszlo Kardos (updated by ChatGPT)

# Base URL and API
bing="https://www.bing.com"
api="/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"

# Random day selector (0–7)
if [[ $1 =~ ^[0-7]$ ]]; then
  day="$1"
else
  day=$(shuf -i 0-7 -n 1)
fi

# Build full API URL
req="$bing/HPImageArchive.aspx?format=js&idx=$day&n=1&mkt=en-US"

# Target directory
path="$HOME/Pictures/Backgrounds/Bing/"
mkdir -p "$path"

# Fetch JSON safely with user-agent
apiResp=$(curl -A "Mozilla/5.0" -s "$req")
if [[ -z "$apiResp" ]]; then
  echo "❌ Nem sikerült letölteni a Bing API választ."
  exit 1
fi

# Extract image URL
urlbase=$(echo "$apiResp" | grep -oP '(?<="urlbase":")[^"]+')
if [[ -z "$urlbase" ]]; then
  echo "❌ Nem található urlbase az API válaszban."
  exit 1
fi

# Próbáljunk UHD-t, ha nem elérhető, fallback 1920x1080
img_url="$bing${urlbase}_UHD.jpg"
if ! curl -A "Mozilla/5.0" --silent --head --fail "$img_url" > /dev/null; then
  img_url="$bing${urlbase}_1920x1080.jpg"
fi

# Extract copyright
copyright=$(echo "$apiResp" | grep -oP '(?<="copyright":")[^"]+' | sed 's/\\u00a9/©/g')

# Get image filename
imgName="${img_url##*/}"

# Download image
echo "⬇️ Letöltés: $img_url"
curl -A "Mozilla/5.0" -s -o "$path$imgName" "$img_url"

# Save copyright info
echo "$copyright" > "$path${imgName%.jpg}.txt"

# Set wallpaper with nitrogen
if command -v nitrogen >/dev/null 2>&1; then
  nitrogen --set-auto "$path$imgName"
else
  echo "⚠️ Nitrogen nem található, háttér nem lett beállítva."
fi

echo "✅ Kész: $path$imgName"
