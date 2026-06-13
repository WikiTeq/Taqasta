#!/usr/bin/env bash
# Wait for run-maintenance-scripts.sh marker; stream web logs to CI output.
set -euo pipefail

MARKER='>>>>> run-maintenance-script.sh <<<<<'
LOG_FILE=/tmp/taqasta-web-init.log

: >"$LOG_FILE"
docker compose logs web >>"$LOG_FILE" 2>&1 || true

docker compose logs -f web 2>&1 | tee -a "$LOG_FILE" &
logs_pid=$!
trap 'kill "$logs_pid" 2>/dev/null; wait "$logs_pid" 2>/dev/null || true' EXIT

while ! grep -Fq "$MARKER" "$LOG_FILE"; do
	sleep 1
done
