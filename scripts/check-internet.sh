#!/bin/bash
#
# Check Internet Connectivity
#
# Returns 0 if internet is available, 1 otherwise
# Can be used by other scripts to quickly check internet status

set -e

# Test hosts
HOSTS=("8.8.8.8" "1.1.1.1" "9.9.9.9")
TIMEOUT=5

# Mock Mode für Tests
if [[ "${MOCK_MODE}" == "true" ]]; then
    MOCK_FILE="$(dirname "$0")/../test/mock-internet.txt"
    if [[ -f "$MOCK_FILE" ]]; then
        if grep -q "true" "$MOCK_FILE"; then
            echo "Internet: Available (Mock)"
            exit 0
        fi
    fi
    echo "Internet: Not available (Mock)"
    exit 1
fi

# Try pinging each host
for host in "${HOSTS[@]}"; do
    if ping -c 1 -W $TIMEOUT "$host" &>/dev/null; then
        echo "Internet: Available (ping $host succeeded)"
        exit 0
    fi
done

echo "Internet: Not available (all pings failed)"
exit 1
