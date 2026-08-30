# Voltronic Inverter MQTT

This add-on monitors a PI30-compatible Voltronic, Axpert, MPP Solar, Voltacon, or Effekta inverter and creates MQTT entities in Home Assistant. It also creates two writable number entities for charging current.

## Configuration

Set `device_id` to a stable identifier, not a changing port number. Recommended values, in order:

1. The full `/dev/serial/by-id/...` path shown in **Settings > System > Hardware > All Hardware**.
2. The filename portion of that path (a partial match is accepted).
3. A udev property such as `ID_SERIAL`, `ID_SERIAL_SHORT`, `ID_PATH`, or `10c4:ea60` (USB vendor ID and product ID).

If the adapter exposes no stable identity, leave `device_id` empty and set `device_path` to `/dev/hidraw0`, `/dev/ttyUSB0`, or another explicit node. `device_id` takes precedence when both are present.

The add-on uses the MQTT broker registered with Home Assistant Supervisor. No broker address or password is needed in the options.

Choose a unique `serial` if you run more than one inverter. It is used as the Home Assistant MQTT device identifier.

## Charging controls

After startup, Home Assistant MQTT discovery creates:

- **Maximum charging current**, which sends PI30 command `MNCHGCxxx`.
- **Maximum utility charging current**, which sends PI30 command `MUCHGCxxx`.

The allowed minimum, maximum, and step are options because supported values differ between inverter models. Set these to values listed by your inverter manual. A command outside that configured range or step is rejected.

Changing current can affect battery safety and inverter limits. Confirm the battery, BMS, cable, and inverter ratings before using these controls. An `ACK` response means the inverter accepted the protocol command; verify the reported setting afterward.

## Other commands

Raw commands are off by default. To enable them, set `allow_raw_commands: true`, then publish an alphanumeric PI30 command to:

```text
<mqtt_topic>/voltronic/<serial>/set/raw
```

Results are published to:

```text
<mqtt_topic>/voltronic/<serial>/command_result
```

## Troubleshooting

The startup log prints the resolved device node. If resolution fails, copy an identifier from Home Assistant's hardware page. For a USB-to-serial adapter, `/dev/serial/by-id/...` is preferable because `/dev/ttyUSB0` can change after a restart.

This code targets the PI30 protocol used by the upstream `docker-voltronic-homeassistant` project. Commands vary on newer PI protocols and some OEM firmware.

