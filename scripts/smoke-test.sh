#!/usr/bin/env bash

set -Eeuo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"
CURL_TIMEOUT="${CURL_TIMEOUT:-5}"

printf 'Waiting for SecureCart at %s ...\n' "$BASE_URL"

for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
    if health_json="$(
        curl \
            --connect-timeout "$CURL_TIMEOUT" \
            --max-time "$CURL_TIMEOUT" \
            -fsS \
            "$BASE_URL/actuator/health" \
            2>/dev/null
    )" \
       && jq -e '.status == "UP"' >/dev/null 2>&1 <<<"$health_json"; then

        printf 'Application is healthy.\n'
        break
    fi

    if (( attempt == MAX_ATTEMPTS )); then
        printf \
            'ERROR: SecureCart did not report status UP after %s attempts.\n' \
            "$MAX_ATTEMPTS" >&2
        exit 1
    fi

    sleep "$SLEEP_SECONDS"
done

printf '\nHealth:\n'

health_json="$(
    curl \
        --connect-timeout "$CURL_TIMEOUT" \
        --max-time "$CURL_TIMEOUT" \
        -fsS \
        "$BASE_URL/actuator/health"
)"

jq . <<<"$health_json"

jq -e '.status == "UP"' >/dev/null <<<"$health_json"

printf '\nProducts:\n'

products_json="$(
    curl \
        --connect-timeout "$CURL_TIMEOUT" \
        --max-time "$CURL_TIMEOUT" \
        -fsS \
        "$BASE_URL/api/products"
)"

jq . <<<"$products_json"

jq -e \
    'type == "array" and length > 0' \
    >/dev/null \
    <<<"$products_json"

printf '\nSmoke test passed: health is UP and the products API returned data.\n'
