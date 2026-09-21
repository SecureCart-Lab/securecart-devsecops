#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-http://host.docker.internal:8080}"
mkdir -p reports/zap
# Baseline scan is intentionally non-destructive. Exit code 2 (warnings) is retained for review.
docker run --rm --network host -v "$PWD/reports/zap:/zap/wrk/:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t "$TARGET" -r zap-report.html -J zap-report.json
