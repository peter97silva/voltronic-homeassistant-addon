# Changelog

## 0.1.4

- Fix MQTT discovery startup by reading add-on options directly from `/data/options.json` in helper processes where Bashio functions are unavailable.
- Fix charge-current command validation and raw-command option handling for the same helper-process environment.

## 0.1.3

- Include `<fcntl.h>` for the POSIX `open()` declaration and `O_RDWR` flag.
- Remove non-standard arithmetic on a `void *` during inverter reads.

## 0.1.2

- Fix GCC 14 build errors caused by passing pointers-to-arrays to `sscanf` `%s` conversions.
- Add explicit field widths and sufficient null-terminator space for inverter status flags.

## 0.1.1

- Fix compilation with GCC 14 by explicitly including `<string>` and `<cstdint>`.
- Bump the add-on version so Home Assistant Supervisor rebuilds the corrected source instead of reusing the 0.1.0 build cache.

## 0.1.0

- Initial Home Assistant add-on release.

