#!/usr/bin/env python3
from datetime import date
import json
import os
import subprocess
from urllib.request import urlopen, Request

FEED_URL = "https://peapix.com/bing/feed?country="
DEFAULT_HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:99.0) Gecko/20100101 Firefox/99.0",
}


def main() -> None:
    if not os.environ.get("DISPLAY", None):
        print("$DISPLAY not set – cannot change wallpaper")
        return

    # Load configuration from environment variable
    country = os.environ.get("BING_WALLPAPER_COUNTRY", "")
    wallpapers_dir = os.environ.get(
        "BING_WALLPAPER_PATH", os.path.expanduser("~/.wallpapers")
    )

    # check store directory
    os.makedirs(wallpapers_dir, exist_ok=True)

    # download feed json
    with urlopen(Request(f"{FEED_URL}{country}", headers=DEFAULT_HEADERS)) as resp:
        feed = json.load(resp)

    # only today's wallpaper
    today = date.today().isoformat()
    today_item = next((item for item in feed if item["date"] == today), None)
    if not today_item:
        print("No wallpaper found for today.")
        return

    today_wallpaper = os.path.join(wallpapers_dir, f"{today}.jpg")
    if not os.path.exists(today_wallpaper):
        with urlopen(Request(today_item["imageUrl"], headers=DEFAULT_HEADERS)) as resp:
            data = resp.read()
        with open(today_wallpaper, "wb") as f:
            f.write(data)
        print(f"Downloaded: {today_wallpaper}")

    # set wallpaper via xfconf-query
    proc = subprocess.run(
        ["xrandr | grep ' connected'"],
        capture_output=True,
        shell=True,
        text=True,
    )
    monitors = [line.split()[0] for line in proc.stdout.split("\n") if line]

    for monitor in monitors:
        prop_name = f"/backdrop/screen0/monitor{monitor}/workspace0/last-image"
        subprocess.run(
            ["xfconf-query", "-c", "xfce4-desktop", "-p", prop_name, "-s", today_wallpaper]
        )


if __name__ == "__main__":
    main()
