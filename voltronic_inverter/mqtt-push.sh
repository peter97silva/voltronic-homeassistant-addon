#!/usr/bin/env bash
set -euo pipefail
source /usr/local/bin/mqtt-common

if ! DATA="$(timeout 15 inverter_poller -1)" || ! jq -e . >/dev/null 2>&1 <<<"$DATA"; then
    echo "Poll returned no valid JSON" >&2
    exit 1
fi

while IFS=$'\t' read -r key value; do
    publish -t "${BASE}/state/${key}" -m "$value"
done < <(jq -r 'to_entries[] | [.key, (.value|tostring)] | @tsv' <<<"$DATA")

publish -r -t "${BASE}/availability" -m online

