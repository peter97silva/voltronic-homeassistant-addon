#!/usr/bin/env bash
MQTT_CONFIG=/data/runtime/mqtt.json
OPTIONS_CONFIG=/data/options.json
MQTT_SERVER="$(jq -r '.server' "$MQTT_CONFIG")"
MQTT_PORT="$(jq -r '.port' "$MQTT_CONFIG")"
MQTT_USERNAME="$(jq -r '.username' "$MQTT_CONFIG")"
MQTT_PASSWORD="$(jq -r '.password' "$MQTT_CONFIG")"
MQTT_TOPIC="$(jq -r '.topic' "$MQTT_CONFIG")"
MQTT_NAME="$(jq -r '.devicename' "$MQTT_CONFIG")"
MQTT_SERIAL="$(jq -r '.serial' "$MQTT_CONFIG")"
BASE="${MQTT_TOPIC}/voltronic/${MQTT_SERIAL}"

MQTT_AUTH=(-h "$MQTT_SERVER" -p "$MQTT_PORT")
if [[ -n "$MQTT_USERNAME" ]]; then
    MQTT_AUTH+=(-u "$MQTT_USERNAME" -P "$MQTT_PASSWORD")
fi

publish() { mosquitto_pub "${MQTT_AUTH[@]}" "$@"; }

# mqtt helper scripts run as ordinary Bash processes, so Bashio shell
# functions are not available here. Read add-on options directly instead.
option() { jq -er --arg key "$1" '.[$key]' "$OPTIONS_CONFIG"; }
option_true() { [[ "$(option "$1")" == "true" ]]; }

