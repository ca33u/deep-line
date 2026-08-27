#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

sdk_config="${GARMIN_SDK_CONFIG:-$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg}"
developer_key="${GARMIN_DEVELOPER_KEY:-developer_key.der}"
device="${1:-fenix7xpronowifi}"
sdk_root=$(tr -d '\r\n' < "$sdk_config")

mkdir -p bin
"$sdk_root/bin/monkeyc" \
    -d "$device" \
    -f monkey.jungle \
    -o "bin/deep-line-$device.prg" \
    -y "$developer_key"
