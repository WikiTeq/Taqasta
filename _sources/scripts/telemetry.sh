#!/bin/sh
# Taqasta opt-out telemetry (WIK-2541).
#
# Privacy: this script sends ONLY the wiki domain and version identifiers to the
# collector URL in TELEMETRY_ENDPOINT. It never collects or transmits page
# content, user data, database contents, credentials, or LocalSettings secrets.
# Set NO_TELEMETRY=1 (any non-empty value) to disable telemetry entirely.
#
# The endpoint is intentionally left empty by default: deployments must set
# TELEMETRY_ENDPOINT explicitly for anything to be sent.
#
# Failure guarantee: every network call has a short timeout and all errors are
# swallowed, so telemetry can never affect wiki operation.

TELEMETRY_INTERVAL="${TELEMETRY_INTERVAL:-86400}"

if [ -n "$NO_TELEMETRY" ]; then
	exit 0
fi

if [ -z "$TELEMETRY_ENDPOINT" ]; then
	exit 0
fi

send_ping() {
	domain=""

	# Prefer the canonical public URL of the wiki ($wgCanonicalServer,
	# e.g. "https://example.org"), falling back to $wgServer and then to
	# MW_SITE_SERVER. Only the domain is extracted for transmission.
	if command -v php >/dev/null 2>&1; then
		domain=$(php /getMediawikiSettings.php --variable=wgCanonicalServer 2>/dev/null)
	fi
	if [ -z "$domain" ] && command -v php >/dev/null 2>&1; then
		domain=$(php /getMediawikiSettings.php --variable=wgServer 2>/dev/null)
	fi
	if [ -z "$domain" ] && [ -n "$MW_SITE_SERVER" ]; then
		domain="$MW_SITE_SERVER"
	fi

	[ -n "$domain" ] || return 0

	payload=$(printf '{"domain":"%s","image_version":"%s","mediawiki_version":"%s"}' \
		"$domain" "${TAQASTA_VERSION:-}" "${MW_VERSION:-}")

	curl --silent --show-error \
		--max-time 10 \
		--connect-timeout 5 \
		--retry 0 \
		-H 'Content-Type: application/json' \
		--user-agent 'Taqasta-Telemetry/1.0' \
		-X POST \
		-d "$payload" \
		"$TELEMETRY_ENDPOINT" >/dev/null 2>&1 || true
}

while :; do
	send_ping
	sleep "$TELEMETRY_INTERVAL"
done
