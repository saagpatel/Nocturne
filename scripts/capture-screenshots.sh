#!/usr/bin/env bash
# Run from any directory. Generates the ignored Xcode project when missing.
# Captures raw app UI;
# the planned headline overlays and physical-device shots remain operator work.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
DERIVED=${DERIVED:-.build/shots}
DEVICE_NAME="iPhone 18 Pro Max"
DEVICE_SLUG="iphone-18-pro-max"
EXPECTED_WIDTH=1320
EXPECTED_HEIGHT=2868
SHOTS=(1 3 4)
BOOTED_DEVICES=()
OVERRIDDEN_DEVICES=()

cleanup() {
    local result=$? device
    trap - EXIT
    set +e
    for device in ${OVERRIDDEN_DEVICES[@]+"${OVERRIDDEN_DEVICES[@]}"}; do
        if ! xcrun simctl status_bar "$device" clear; then
            printf "Failed to clear status bar override for %s\n" "$device" >&2
            result=1
        fi
    done
    for device in ${BOOTED_DEVICES[@]+"${BOOTED_DEVICES[@]}"}; do
        if ! xcrun simctl shutdown "$device"; then
            printf "Failed to shut down script-booted simulator %s\n" "$device" >&2
            result=1
        fi
    done
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for command in xcodebuild xcrun sips python3; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf "Required command is missing: %s\n" "$command" >&2
        exit 1
    fi
done
if [[ ! -d Nocturne.xcodeproj ]]; then
    if ! command -v xcodegen >/dev/null 2>&1; then
        printf "Nocturne.xcodeproj is missing and xcodegen is unavailable. Install XcodeGen first.\n" >&2
        exit 1
    fi
    xcodegen generate
fi

printf "02 OPERATOR: capture on device — comparison from a successful physical-device reading.\n"
xcodebuild build -project Nocturne.xcodeproj -scheme Nocturne \
    -configuration Debug -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO

PRODUCTS="$DERIVED/Build/Products/Debug-iphonesimulator"
APPS=()
for candidate in "$PRODUCTS"/*.app; do
    [[ -d "$candidate" ]] && APPS+=("$candidate")
done
if [[ ${#APPS[@]} -ne 1 ]]; then
    printf "Expected one built simulator app in %s; found %s.\n" "$PRODUCTS" "${#APPS[@]}" >&2
    exit 1
fi
APP=${APPS[0]}
BUNDLE_ID=$(python3 -c 'import plistlib, sys
with open(sys.argv[1], "rb") as source:
    value = plistlib.load(source).get("CFBundleIdentifier")
if not isinstance(value, str) or not value:
    sys.exit("Built app Info.plist has no CFBundleIdentifier")
print(value)' "$APP/Info.plist")

# Prefer the newest available iOS runtime when several contain this device name.
DEVICE_RECORD=$(xcrun simctl list devices available -j | python3 -c 'import json, re, sys
name = sys.argv[1]
matches = []
for runtime, devices in json.load(sys.stdin).get("devices", {}).items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in re.findall(r"[0-9]+", runtime.split(".iOS-", 1)[1]))
    for device in devices:
        if device.get("name") == name and device.get("isAvailable", True):
            matches.append((version, device.get("state") == "Booted", device["udid"], device["state"]))
if not matches:
    sys.exit("Missing available simulator: " + name + ". Install its iOS runtime and create it in Xcode first.")
_, _, udid, state = max(matches)
print(udid + "\t" + state)' "$DEVICE_NAME")
IFS=$'\t' read -r DEVICE_ID DEVICE_STATE <<< "$DEVICE_RECORD"
if [[ "$DEVICE_STATE" != Booted ]]; then
    BOOTED_DEVICES+=("$DEVICE_ID")
    xcrun simctl boot "$DEVICE_ID"
fi
xcrun simctl bootstatus "$DEVICE_ID" -b
OVERRIDDEN_DEVICES+=("$DEVICE_ID")
xcrun simctl status_bar "$DEVICE_ID" override --time 9:41 \
    --dataNetwork wifi --wifiBars 3 --cellularBars 4 \
    --batteryState charged --batteryLevel 100
xcrun simctl install "$DEVICE_ID" "$APP"
xcrun simctl ui "$DEVICE_ID" appearance dark

# Make this app the previous foreground app before any captured launch, clearing
# the cross-app status bar back link. Termination is safe if it is not running.
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" -AppStoreScreenshot "${SHOTS[0]}"
sleep 2
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true

OUTPUT="screenshots/appstore/$DEVICE_SLUG"
mkdir -p "$OUTPUT"
for shot in "${SHOTS[@]}"; do
    wait_name="SHOT_${shot}_WAIT_SECONDS"
    settle=${!wait_name:-${SHOT_WAIT_SECONDS:-4}}
    if [[ ! "$settle" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        printf "Invalid %s/SHOT_WAIT_SECONDS: %s (expected seconds).\n" "$wait_name" "$settle" >&2
        exit 1
    fi
    printf -v filename "%s/%02d.png" "$OUTPUT" "$shot"
    # A freshly installed or already terminated app has no process to terminate.
    xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" -AppStoreScreenshot "$shot"
    sleep "$settle"
    xcrun simctl io "$DEVICE_ID" screenshot "$filename"
    dimensions=$(sips -g pixelWidth -g pixelHeight "$filename")
    width=$(printf "%s\n" "$dimensions" | awk '$1 == "pixelWidth:" { print $2 }')
    height=$(printf "%s\n" "$dimensions" | awk '$1 == "pixelHeight:" { print $2 }')
    if [[ "$width" != "$EXPECTED_WIDTH" || "$height" != "$EXPECTED_HEIGHT" ]]; then
        printf "Wrong screenshot size for %s: %sx%s; expected %sx%s.\n" \
            "$filename" "$width" "$height" "$EXPECTED_WIDTH" "$EXPECTED_HEIGHT" >&2
        exit 1
    fi
    printf "Captured %s (%sx%s).\n" "$filename" "$width" "$height"
done
