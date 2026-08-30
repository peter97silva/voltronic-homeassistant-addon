#!/usr/bin/env bash
set -euo pipefail
source /usr/local/bin/mqtt-common

MANUFACTURER="$(jq -r '.manufacturer' "$MQTT_CONFIG")"
MODEL="$(jq -r '.model' "$MQTT_CONFIG")"
DEVICE="$(jq -nc --arg id "$MQTT_SERIAL" --arg name "$MQTT_NAME" --arg mf "$MANUFACTURER" --arg mdl "$MODEL" '{identifiers:[$id],name:$name,manufacturer:$mf,model:$mdl}')"

sensor() {
    local key="$1" name="$2" unit="${3:-}" class="${4:-}"
    jq -nc --arg name "$name" --arg uid "${MQTT_SERIAL}_${key}" --arg state "${BASE}/state/${key}" --arg unit "$unit" --arg class "$class" --argjson device "$DEVICE" \
      --arg available "${BASE}/availability" \
      '{name:$name,unique_id:$uid,state_topic:$state,availability_topic:$available,device:$device} + (if $unit != "" then {unit_of_measurement:$unit} else {} end) + (if $class != "" then {device_class:$class,state_class:"measurement"} else {} end)' \
      | publish -r -t "${MQTT_TOPIC}/sensor/${MQTT_SERIAL}/${key}/config" -l
}

number() {
    local key="$1" name="$2" state_key="$3" min="$4" max="$5" step="$6"
    jq -nc --arg name "$name" --arg uid "${MQTT_SERIAL}_${key}" --arg state "${BASE}/state/${state_key}" --arg cmd "${BASE}/set/${key}" --arg available "${BASE}/availability" --argjson min "$min" --argjson max "$max" --argjson step "$step" --argjson device "$DEVICE" \
      '{name:$name,unique_id:$uid,state_topic:$state,command_topic:$cmd,availability_topic:$available,min:$min,max:$max,step:$step,mode:"box",unit_of_measurement:"A",device_class:"current",device:$device}' \
      | publish -r -t "${MQTT_TOPIC}/number/${MQTT_SERIAL}/${key}/config" -l
}

sensor Inverter_mode "Inverter mode"
sensor Protocol "Detected protocol"
sensor AC_grid_voltage "AC grid voltage" V voltage
sensor AC_grid_frequency "AC grid frequency" Hz frequency
sensor AC_out_voltage "AC output voltage" V voltage
sensor AC_out_frequency "AC output frequency" Hz frequency
sensor PV_in_voltage "PV input voltage" V voltage
sensor PV_in_current "PV input current" A current
sensor PV_in_watts "PV input power" W power
sensor PV_charging_power "PV charging power" W power
sensor Load_pct "Load" "%"
sensor Load_watt "Load power" W power
sensor Battery_capacity "Battery capacity" "%" battery
sensor Battery_voltage "Battery voltage" V voltage
sensor Battery_charge_current "Battery charge current" A current
sensor Battery_discharge_current "Battery discharge current" A current
sensor Heatsink_temperature "Heatsink temperature" "°C" temperature
sensor Charger_source_priority "Charger source priority"
sensor Out_source_priority "Output source priority"
sensor Warnings "Warnings"

number max_charge_current "Maximum charging current" Max_charge_current \
  "$(option 'max_charge_current_min')" "$(option 'max_charge_current_max')" "$(option 'max_charge_current_step')"
number utility_charge_current "Maximum utility charging current" Max_grid_charge_current \
  "$(option 'utility_charge_current_min')" "$(option 'utility_charge_current_max')" "$(option 'utility_charge_current_step')"

publish -r -t "${BASE}/availability" -m online

