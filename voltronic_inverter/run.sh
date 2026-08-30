#!/usr/bin/with-contenv bashio
set -euo pipefail

resolve_device() {
    local requested="$1" candidate property

    if [[ -e "$requested" ]]; then
        readlink -f "$requested"
        return 0
    fi

    if [[ -d /dev/serial/by-id ]]; then
        while IFS= read -r candidate; do
            [[ "$(basename "$candidate")" == *"$requested"* ]] || continue
            readlink -f "$candidate"
            return 0
        done < <(find /dev/serial/by-id -maxdepth 1 -type l | sort)
    fi

    for candidate in /dev/ttyUSB* /dev/ttyACM* /dev/hidraw* /dev/ttyS*; do
        [[ -e "$candidate" ]] || continue
        property="$(udevadm info --query=property --name="$candidate" 2>/dev/null || true)"
        if [[ "$requested" =~ ^([[:xdigit:]]{4}):([[:xdigit:]]{4})$ ]] \
          && grep -Eqi "^ID_VENDOR_ID=${BASH_REMATCH[1]}$" <<<"$property" \
          && grep -Eqi "^ID_MODEL_ID=${BASH_REMATCH[2]}$" <<<"$property"; then
            readlink -f "$candidate"
            return 0
        fi
        if grep -Fqi -- "$requested" <<<"$property"; then
            readlink -f "$candidate"
            return 0
        fi
    done
    return 1
}

DEVICE_ID="$(bashio::config 'device_id')"
DEVICE_PATH="$(bashio::config 'device_path')"

if [[ -n "$DEVICE_ID" ]]; then
    if ! DEVICE="$(resolve_device "$DEVICE_ID")"; then
        bashio::log.fatal "No inverter device matches device_id: $DEVICE_ID"
        bashio::log.info "Use a value shown by: ls -l /dev/serial/by-id"
        bashio::log.info "You may also use ID_SERIAL, ID_SERIAL_SHORT, ID_PATH, or a four-digit VID:PID from udevadm info."
        exit 1
    fi
elif [[ -n "$DEVICE_PATH" && -e "$DEVICE_PATH" ]]; then
    DEVICE="$(readlink -f "$DEVICE_PATH")"
else
    bashio::log.fatal "Set device_id (recommended) or device_path in the add-on configuration."
    exit 1
fi

MQTT_JSON="$(curl -fsS -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/services/mqtt)"
if [[ "$(jq -r '.result' <<<"$MQTT_JSON")" != "ok" ]]; then
    bashio::log.fatal "The Supervisor MQTT service is unavailable. Install/configure an MQTT broker first."
    exit 1
fi

mkdir -p /etc/inverter /data/runtime
cat > /etc/inverter/inverter.conf <<EOF
device=$DEVICE
amperage_factor=$(bashio::config 'amperage_factor')
watt_factor=$(bashio::config 'watt_factor')
EOF

jq -n \
  --arg server "$(jq -r '.data.host' <<<"$MQTT_JSON")" \
  --arg port "$(jq -r '.data.port' <<<"$MQTT_JSON")" \
  --arg username "$(jq -r '.data.username // ""' <<<"$MQTT_JSON")" \
  --arg password "$(jq -r '.data.password // ""' <<<"$MQTT_JSON")" \
  --arg topic "$(bashio::config 'mqtt_topic')" \
  --arg devicename "$(bashio::config 'device_name')" \
  --arg manufacturer "$(bashio::config 'manufacturer')" \
  --arg model "$(bashio::config 'model')" \
  --arg serial "$(bashio::config 'serial')" \
  '{server:$server,port:$port,username:$username,password:$password,topic:$topic,devicename:$devicename,manufacturer:$manufacturer,model:$model,serial:$serial}' \
  > /data/runtime/mqtt.json

bashio::log.info "Using inverter device $DEVICE (configured ID: ${DEVICE_ID:-$DEVICE_PATH})"
mqtt-init
mqtt-subscriber &
SUBSCRIBER_PID=$!
trap 'kill "$SUBSCRIBER_PID" 2>/dev/null || true' EXIT INT TERM

INTERVAL="$(bashio::config 'poll_interval')"
while true; do
    mqtt-push || bashio::log.warning "Inverter poll failed; retrying in ${INTERVAL}s"
    sleep "$INTERVAL"
done
