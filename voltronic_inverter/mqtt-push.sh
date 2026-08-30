#!/usr/bin/env bash
set -euo pipefail
source /usr/local/bin/mqtt-common

POLL_STATUS=0
RAW_DATA="$(timeout 35 inverter_poller -1 -d 2>&1)" || POLL_STATUS=$?
DATA="$(awk '/^\{/{found=1} found{print} /^\}/{if(found) exit}' <<<"$RAW_DATA")"

if (( POLL_STATUS != 0 )) || ! jq -e . >/dev/null 2>&1 <<<"$DATA"; then
    echo "Poll returned no valid JSON (exit status: $POLL_STATUS)" >&2
    echo "$RAW_DATA" >&2
    exit 1
fi

while IFS=$'\t' read -r key value; do
    publish -t "${BASE}/state/${key}" -m "$value"
done < <(jq -r 'to_entries[] | [.key, (.value|tostring)] | @tsv' <<<"$DATA")

publish -r -t "${BASE}/availability" -m online

