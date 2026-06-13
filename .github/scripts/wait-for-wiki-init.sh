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

fail_fast() {
	local fatal_count

	fatal_count=$(grep -cE 'Fatal error:|PHP Fatal error:' "$LOG_FILE" 2>/dev/null || true)
	if [ "$fatal_count" -eq 0 ]; then
		return 1
	fi

	if grep -Fq 'Check wiki settings for errors' "$LOG_FILE" \
		|| grep -Fq 'An error occurred while checking the wiki settings' "$LOG_FILE"; then
		echo "Fail-fast: web init failed during settings check (fatal=$fatal_count)" >&2
		return 0
	fi

	return 1
}

while ! grep -Fq "$MARKER" "$LOG_FILE"; do
	if fail_fast; then
		tail -40 "$LOG_FILE" >&2
		exit 1
	fi
	sleep 1
done
