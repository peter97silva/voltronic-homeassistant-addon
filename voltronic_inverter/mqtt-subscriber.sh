#!/usr/bin/env bash
set -euo pipefail
source /usr/local/bin/mqtt-common

valid_number() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= $2 && $1 <= $3 && ($1 - $2) % $4 == 0 ))
}

send_command() {
    local command="$1" reply
    reply="$(timeout 15 inverter_poller -r "$command" 2>&1 || true)"
    echo "Command $command: $reply"
    publish -t "${BASE}/command_result" -m "$command: $reply"
}

mosquitto_sub "${MQTT_AUTH[@]}" -v \
  -t "${BASE}/set/max_charge_current" \
  -t "${BASE}/set/utility_charge_current" \
  -t "${BASE}/set/raw" | while read -r topic payload; do
    case "$topic" in
      "${BASE}/set/max_charge_current")
        min="$(bashio::config 'max_charge_current_min')"; max="$(bashio::config 'max_charge_current_max')"; step="$(bashio::config 'max_charge_current_step')"
        valid_number "$payload" "$min" "$max" "$step" && send_command "MNCHGC$(printf '%03d' "$payload")" || echo "Rejected invalid maximum charge current: $payload" >&2
        ;;
      "${BASE}/set/utility_charge_current")
        min="$(bashio::config 'utility_charge_current_min')"; max="$(bashio::config 'utility_charge_current_max')"; step="$(bashio::config 'utility_charge_current_step')"
        valid_number "$payload" "$min" "$max" "$step" && send_command "MUCHGC$(printf '%03d' "$payload")" || echo "Rejected invalid utility charge current: $payload" >&2
        ;;
      "${BASE}/set/raw")
        if bashio::config.true 'allow_raw_commands' && [[ "$payload" =~ ^[A-Za-z0-9.]{2,16}$ ]]; then
            send_command "$payload"
        else
            echo "Rejected raw command (disabled or invalid)" >&2
        fi
        ;;
    esac
done

