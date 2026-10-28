#!/bin/sh
# Pulls everything needed to reconstruct a car cold-start failure from the
# connected Pixel. Run it the same day as the failure: logcat holds about six
# hours (after `adb logcat -G 64M`, which a reboot resets) and the Bluetooth
# media-key log keeps only the last 20 key presses.
set -e
out="${1:-$HOME/Desktop/jellybox-logs-$(date +%Y%m%d-%H%M)}"
mkdir -p "$out"
adb pull /sdcard/Android/data/com.prodigytech.jellybox/files/jellybox.log "$out/jellybox.log"
adb logcat -d -v threadtime > "$out/logcat.txt"
adb logcat -d -v threadtime -b system > "$out/logcat-system.txt"
adb shell dumpsys bluetooth_manager > "$out/bluetooth.txt"
adb shell dumpsys media_session > "$out/media_session.txt"
adb shell dumpsys usagestats > "$out/usagestats.txt"
adb shell dumpsys activity exit-info com.prodigytech.jellybox > "$out/exit-info.txt"
adb shell dumpsys activity services com.prodigytech.jellybox > "$out/services.txt"
adb shell dumpsys audio > "$out/audio.txt"
adb logcat -G 64M
echo "saved to $out"
