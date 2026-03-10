#!/bin/bash

# ─────────────────────────────────────────────
# Internet Watchdog Script for Raspberry Pi
# Checks internet connectivity and restarts
# networking if the connection is down.
# ─────────────────────────────────────────────

# CONFIG
PING_HOST="8.8.8.8"          # Host to ping
PING_COUNT=3                  # Number of ping attempts
PING_TIMEOUT=5                # Seconds before ping times out
LOG_FILE="/var/log/internet_watchdog.log"
MAX_LOG_LINES=500             # Rotate log after this many lines

# Detect which network service is available
if systemctl list-units --type=service | grep -q "NetworkManager.service"; then
    NETWORK_SERVICE="NetworkManager"
elif systemctl list-units --type=service | grep -q "dhcpcd.service"; then
    NETWORK_SERVICE="dhcpcd"
else
    NETWORK_SERVICE="networking"
fi

# ─────────────────────────────────────────────
# FUNCTIONS
# ─────────────────────────────────────────────

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        local line_count
        line_count=$(wc -l < "$LOG_FILE")
        if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
            tail -n 200 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
            log "Log rotated (was ${line_count} lines)"
        fi
    fi
}

check_internet() {
    ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_HOST" > /dev/null 2>&1
    return $?
}

restart_network() {
    log "⚠️  Internet is DOWN. Restarting '$NETWORK_SERVICE'..."
    sudo systemctl restart "$NETWORK_SERVICE"
    sleep 10  # Wait for reconnection

    if check_internet; then
        log "✅ Internet RESTORED after restarting $NETWORK_SERVICE."
    else
        log "❌ Internet still DOWN after restart. Manual intervention may be needed."
    fi
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────

rotate_log

if check_internet; then
    log "✅ Internet is UP."
else
    restart_network
fi
