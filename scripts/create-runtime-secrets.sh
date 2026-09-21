#!/usr/bin/env bash
set -euo pipefail

: "${DB_PASSWORD:?export DB_PASSWORD first}"
: "${APP_USER_PASSWORD:?export APP_USER_PASSWORD first}"
: "${APP_ADMIN_PASSWORD:?export APP_ADMIN_PASSWORD first}"

kubectl create namespace securecart --dry-run=client -o yaml | kubectl apply -f -
kubectl -n securecart create secret generic securecart-db-bootstrap \
  --from-literal=postgres-password="$DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n securecart create secret generic securecart-app-bootstrap \
  --from-literal=db-password="$DB_PASSWORD" \
  --from-literal=user-password="$APP_USER_PASSWORD" \
  --from-literal=admin-password="$APP_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
  kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n monitoring create secret generic slack-webhook \
    --from-literal=url="$SLACK_WEBHOOK_URL" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n falco create secret generic falcosidekick-config \
    --from-literal=SLACK_WEBHOOKURL="$SLACK_WEBHOOK_URL" \
    --dry-run=client -o yaml | kubectl apply -f -
fi
