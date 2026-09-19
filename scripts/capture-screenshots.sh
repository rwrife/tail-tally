#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR
if [[ $# != 1 ]]; then
  echo 'Usage: scripts/capture-screenshots.sh <dedicated-iPhone-11-Pro-Max-simulator-UDID>' >&2
  exit 1
fi
simulator="$1"
output='app-store/screenshots/6.5-inch'
mkdir -p "$output"
xcodebuild -project TailTally.xcodeproj -scheme TailTally -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build > /tmp/tail-tally-screenshot-build.log 2>&1
xcrun simctl bootstatus "$simulator" -b
xcrun simctl status_bar "$simulator" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
xcrun simctl ui "$simulator" appearance light
xcrun simctl install "$simulator" build/Build/Products/Debug-iphonesimulator/TailTally.app
names=('01-today' '02-household' '03-history' '04-settings')
for tab in 0 1 2 3; do
  xcrun simctl terminate "$simulator" com.rwrife.tailTally >/dev/null 2>&1 || true
  xcrun simctl launch "$simulator" com.rwrife.tailTally --screenshots "--tab=$tab"
  sleep 2
  xcrun simctl io "$simulator" screenshot "$output/${names[$tab]}.png"
done
sips -g pixelWidth -g pixelHeight "$output"/*.png
