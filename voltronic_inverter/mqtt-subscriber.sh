#!/usr/bin/env bash
set -euo pipefail
source /usr/local/bin/mqtt-common

valid_number() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= $2 && $1 <= $3 && ($1 - $2) % $4 == 0 ))
}

send_command() {
    local command="$1" reply status=0 result
    reply="$(timeout 20 inverter_poller -r "$command" -d 2>&1)" || status=$?

    if (( status == 0 )) && grep -Eq '^Reply:[[:space:]]+ACK[[:space:]]*$' <<<"$reply"; then
        result="$command: ACK"
        echo "Command accepted: $result"
        publish -t "${BASE}/command_result" -m "$result"
        return 0
    fi

    result="$command: FAILED (exit status $status)"
    echo "Command failed: $result" >&2
    echo "$reply" >&2
    publish -t "${BASE}/command_result" -m "$result"
    return 1
}

mosquitto_sub "${MQTT_AUTH[@]}" -v \
  -t "${BASE}/set/max_charge_current" \
  -t "${BASE}/set/utility_charge_current" \
  -t "${BASE}/set/output_source_priority" \
  -t "${BASE}/set/charger_source_priority" \
  -t "${BASE}/set/raw" | while read -r topic payload; do
    case "$topic" in
      "${BASE}/set/max_charge_current")
        min="$(option 'max_charge_current_min')"; max="$(option 'max_charge_current_max')"; step="$(option 'max_charge_current_step')"
        valid_number "$payload" "$min" "$max" "$step" && send_command "MNCHGC$(printf '%03d' "$payload")" || echo "Rejected invalid maximum charge current: $payload" >&2
        ;;
      "${BASE}/set/utility_charge_current")
        min="$(option 'utility_charge_current_min')"; max="$(option 'utility_charge_current_max')"; step="$(option 'utility_charge_current_step')"
        valid_number "$payload" "$min" "$max" "$step" && send_command "MUCHGC$(printf '%03d' "$payload")" || echo "Rejected invalid utility charge current: $payload" >&2
        ;;
      "${BASE}/set/output_source_priority")
        case "$payload" in
          "Utility-Solar-Battery") send_command "POP00" || true ;;
          "Solar-Utility-Battery") send_command "POP01" || true ;;
          "Solar-Battery-Utility") send_command "POP02" || true ;;
          *) echo "Rejected invalid output source priority: $payload" >&2 ;;
        esac
        ;;
      "${BASE}/set/charger_source_priority")
        case "$payload" in
          "Utility first") send_command "PCP00" || true ;;
          "Solar first") send_command "PCP01" || true ;;
          "Solar and utility") send_command "PCP02" || true ;;
          "Solar only") send_command "PCP03" || true ;;
          *) echo "Rejected invalid charger source priority: $payload" >&2 ;;
        esac
        ;;
      "${BASE}/set/raw")
        if option_true 'allow_raw_commands' && [[ "$payload" =~ ^[A-Za-z0-9.]{2,16}$ ]]; then
            send_command "$payload"
        else
            echo "Rejected raw command (disabled or invalid)" >&2
        fi
        ;;
    esac
done

