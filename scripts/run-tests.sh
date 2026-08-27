#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

sdk_config="${GARMIN_SDK_CONFIG:-$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg}"
developer_key="${GARMIN_DEVELOPER_KEY:-developer_key.der}"
sdk_root=$(tr -d '\r\n' < "$sdk_config")
monkeybrains="$sdk_root/bin/monkeybrains.jar"
simulator="$sdk_root/bin/ConnectIQ.app/Contents/MacOS/simulator"
test_program="/tmp/deep-line-tests.prg"
test_log="/tmp/deep-line-tests.log"

cleanup() {
    if [ -n "${simulator_pid:-}" ]; then
        kill "$simulator_pid" 2>/dev/null || true
    fi
    rm -f "$test_program" "$test_log"
}

trap cleanup EXIT INT TERM

java \
    -Xms1g \
    -Djava.awt.headless=true \
    -Dfile.encoding=UTF-8 \
    -classpath "$monkeybrains" \
    com.garmin.monkeybrains.Monkeybrains \
    -t \
    -l 3 \
    -d fenix7xpronowifi \
    -f monkey.jungle \
    -o "$test_program" \
    -y "$developer_key"

"$simulator" &
simulator_pid=$!
sleep 3

set +e
"$sdk_root/bin/monkeydo" "$test_program" fenix7xpronowifi -t >"$test_log" 2>&1
set -e

cat "$test_log"
grep -q "PASSED (passed=6, failed=0, errors=0)" "$test_log"
