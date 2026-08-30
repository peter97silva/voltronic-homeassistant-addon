# Voltronic Inverter Home Assistant add-on

A native Home Assistant add-on based on [catalinbordan/docker-voltronic-homeassistant](https://github.com/catalinbordan/docker-voltronic-homeassistant).

It resolves the inverter from a stable hardware/device ID instead of relying on a changing `/dev/ttyUSB0` or `/dev/hidraw0` number. MQTT discovery creates monitoring sensors and controls for total and utility charging current.

## Install

1. In Home Assistant, open **Settings > Add-ons > Add-on Store > Repositories** and add `https://github.com/peter97silva/voltronic-homeassistant-addon`.
2. Install **Voltronic Inverter MQTT**.
3. In **Settings > System > Hardware > All Hardware**, locate the inverter cable and copy its `/dev/serial/by-id/...` identifier into `device_id`.
4. Start the add-on and inspect its log. The entities will appear through MQTT discovery.

See the add-on Documentation tab for configuration, command, and safety details.

## Credits and license

The inverter poller is derived from the GPL-3.0 upstream project and remains under GPL-3.0. See `LICENSE`.
