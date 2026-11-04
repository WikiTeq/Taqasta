#!/bin/sh
# WIK-2057: migrate writable bind-mount directories to Docker named volumes.
#
# Taqasta now declares all writable state (database, MediaWiki volume) as
# Docker named volumes. Existing VPS deployments that keep this state in
# bind-mount directories on the host must copy it into the named volumes
# once, before switching to the updated compose files.
#
# The script is idempotent: it can be re-run after an interrupted migration.
# It is DRY-RUN by default; pass --apply to actually move data.
# It never starts or recreates containers; it only stops services if they
# are running and were started with the compose file being used.
#
# Usage:
#   scripts/migrate-binds-to-volumes.sh [options]
#
# Options:
#   --apply          Perform the migration (default: dry-run only)
#   -f FILE          Compose file(s); repeatable, passed through to docker
#                    compose (default: docker-compose.sample.yml)
#   -p PROJECT       Compose project name (default: current directory name)
#   -d DIR           Directory containing the legacy bind-mount data
#                    (default: parent directory of this script)
#   --db-dir DIR     Legacy database datadir      (default: <dir>/mysql)
#   --mw-dir DIR     Legacy MediaWiki volume dir  (default: <dir>/images)
#   --skip-db        Do not migrate the database datadir
#   --skip-mw        Do not migrate the MediaWiki volume dir
#   -h, --help       Show this help
#
# What it does per volume:
#   1. stop the stack (docker compose stop; containers are kept)
#   2. create the named volume if missing (idempotent)
#   3. seed it from the legacy dir with a temporary helper container
#      (rsync if available in the helper image, otherwise cp -a);
#      existing files in the volume are NOT overwritten (--ignore-existing),
#      so re-runs never clobber already-migrated data
#   4. verify: compare file counts and byte sizes between the legacy dir and
#      the volume; report mismatches and exit non-zero
#   5. rename the legacy dir to <name>.migrated-<timestamp> (apply mode only,
#      never deleted), so the old data remains as a rollback snapshot
#
# Rollback: point docker-compose back at the previous file (bind mounts),
# or rename <name>.migrated-<timestamp> back to <name> and start the stack.

set -u

APPLY=0
COMPOSE_FILES=""
PROJECT=""
BASE_DIR=""
DB_DIR=""
MW_DIR=""
SKIP_DB=0
SKIP_MW=0

HELPER_IMAGE=${MIGRATE_HELPER_IMAGE:-alpine:3.20}
DB_VOLUME=${TAQASTA_DB_VOLUME:-taqasta_db_data}
MW_VOLUME=${TAQASTA_MW_VOLUME:-taqasta_mw_volume}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
WIK-2057: migrate writable bind-mount directories to Docker named volumes.

Usage: scripts/migrate-binds-to-volumes.sh [options]

Options:
  --apply          Perform the migration (default: dry-run only)
  -f FILE          Compose file(s); repeatable, passed through to docker
                   compose (default: docker-compose.sample.yml)
  -p PROJECT       Compose project name (default: current directory name)
  -d DIR           Directory containing the legacy bind-mount data
                   (default: parent directory of this script)
  --db-dir DIR     Legacy database datadir      (default: <dir>/mysql)
  --mw-dir DIR     Legacy MediaWiki volume dir  (default: <dir>/images)
  --skip-db        Do not migrate the database datadir
  --skip-mw        Do not migrate the MediaWiki volume dir
  -h, --help       Show this help

The script is idempotent and never deletes data: migrated directories are
renamed to <name>.migrated-<timestamp> as a rollback snapshot. To roll back,
point compose back at the previous bind-mount layout and start the stack.
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case $1 in
        --apply) APPLY=1 ;;
        -f)
            [ $# -ge 2 ] || die "-f requires an argument"
            COMPOSE_FILES="$COMPOSE_FILES -f $2"
            shift
            ;;
        -p)
            [ $# -ge 2 ] || die "-p requires an argument"
            PROJECT=$2
            shift
            ;;
        -d)
            [ $# -ge 2 ] || die "-d requires an argument"
            BASE_DIR=$2
            shift
            ;;
        --db-dir)
            [ $# -ge 2 ] || die "--db-dir requires an argument"
            DB_DIR=$2
            shift
            ;;
        --mw-dir)
            [ $# -ge 2 ] || die "--mw-dir requires an argument"
            MW_DIR=$2
            shift
            ;;
        --skip-db) SKIP_DB=1 ;;
        --skip-mw) SKIP_MW=1 ;;
        -h|--help) usage ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

command -v docker >/dev/null 2>&1 || die "required command not found: docker"

# Concurrency guard: only one migration may touch the volumes at a time.
# Enforced in apply mode only; a dry run takes no lock and needs no flock.
if [ "$APPLY" -eq 1 ]; then
    if ! command -v flock >/dev/null 2>&1; then
        die "flock required for apply mode"
    fi
    LOCK_DIR="${TMPDIR:-/tmp}/taqasta-migrate.lock"
    exec 9>"$LOCK_DIR" || die "cannot open lock file $LOCK_DIR"
    flock -n 9 || die "another migration appears to be in progress (lock: $LOCK_DIR)"
fi

compose() {
    # shellcheck disable=SC2086
    docker compose $COMPOSE_FILES -p "$PROJECT" "$@"
}

stop_stack() {
    echo "== Stopping the stack (containers are kept, not removed)"
    if [ "$APPLY" -eq 1 ]; then
        compose stop || die "'docker compose stop' failed"
    else
        echo "   DRY-RUN: would run: docker compose$COMPOSE_FILES -p $PROJECT stop"
    fi
}

start_hint() {
    cat <<EOF

Migration finished. Start the stack with the NEW compose files, e.g.:

    docker compose$COMPOSE_FILES -p $PROJECT up -d

EOF
}

# Exact logical content bytes (filesystem-independent); reads every file,
# which is acceptable for a one-off migration verification
content_bytes() {
    find "$1" -type f ! -type l -exec cat {} + 2>/dev/null | wc -c | tr -d ' '
}

# File count excluding symlinks (a symlink to a missing file is not -type f)
count_files() {
    find "$1" -type f ! -type l 2>/dev/null | wc -l | tr -d ' '
}

seed_volume() {
    # $1 = host directory, $2 = volume name, $3 = human label
    src_dir=$1
    vol=$2
    label=$3

    if [ ! -d "$src_dir" ]; then
        echo "== [$label] no legacy directory at $src_dir - skipping"
        return 0
    fi

    echo "== [$label] migrating $src_dir -> volume '$vol'"

    if [ "$APPLY" -eq 0 ]; then
        echo "   DRY-RUN summary for $label:"
        echo "     source files: $(count_files "$src_dir")"
        echo "     source bytes: $(content_bytes "$src_dir")"
        return 0
    fi

    docker volume inspect "$vol" >/dev/null 2>&1 ||
        docker volume create "$vol" >/dev/null ||
        die "could not create volume $vol"

    echo "   copying data (rsync when available, cp fallback)... this can take a while"
    docker run --rm \
        -v "$src_dir":/src:ro \
        -v "$vol":/dest \
        "$HELPER_IMAGE" \
        sh -c '
            set -e
            if command -v rsync >/dev/null 2>&1; then
                rsync -a --ignore-existing /src/ /dest/
            elif [ -e /dest/.migrated-from-bind ]; then
                echo "volume already seeded before; skipping copy (install rsync in the helper image for incremental top-up)" >&2
            else
                cd /src || exit 1
                cp -a . /dest/
                touch /dest/.migrated-from-bind
            fi
        ' || die "copying into $vol failed"

    echo "   verifying counts/sizes..."
    src_files=$(count_files "$src_dir")
    src_bytes=$(content_bytes "$src_dir")
    vol_files=$(docker run --rm \
        -v "$vol":/mnt:ro \
        "$HELPER_IMAGE" \
        sh -c 'find /mnt -type f ! -name .migrated-from-bind | wc -l')
    vol_bytes=$(docker run --rm \
        -v "$vol":/mnt:ro \
        "$HELPER_IMAGE" \
        sh -c 'find /mnt -type f ! -name .migrated-from-bind -exec cat {} + | wc -c')

    echo "     source : $src_files files, $src_bytes bytes"
    echo "     volume : $vol_files files, $vol_bytes bytes"

    [ "${src_bytes:-0}" -eq "${vol_bytes:-0}" ] ||
        die "byte totals differ for $label ($src_bytes vs $vol_bytes); aborting before rename"
    [ "${src_files:-0}" -le "${vol_files:-0}" ] ||
        die "volume has fewer files than the source for $label; aborting before rename"

    ts=$(date +%Y%m%d-%H%M%S)
    mv "$src_dir" "${src_dir}.migrated-$ts" ||
        die "could not rename $src_dir"
    echo "   OK - renamed source to ${src_dir}.migrated-$ts (kept as rollback)"
}

[ -n "$BASE_DIR" ] || BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
[ -n "$PROJECT" ] || PROJECT=$(basename "$(cd "$BASE_DIR" && pwd)")

if [ -z "$COMPOSE_FILES" ]; then
    if [ -f "$BASE_DIR/docker-compose.sample.yml" ]; then
        COMPOSE_FILES="-f $BASE_DIR/docker-compose.sample.yml"
    fi
fi

[ "$SKIP_DB" -eq 1 ] || [ -n "$DB_DIR" ] || DB_DIR="$BASE_DIR/mysql"
[ "$SKIP_MW" -eq 1 ] || [ -n "$MW_DIR" ] || MW_DIR="$BASE_DIR/images"

echo "Taqasta bind-to-volume migration (WIK-2057)"
echo "  project : $PROJECT"
echo "  compose :${COMPOSE_FILES:- <defaults>}"
echo "  db dir  : $([ "$SKIP_DB" -eq 1 ] && echo '(skipped)' || printf %s "$DB_DIR")"
echo "  mw dir  : $([ "$SKIP_MW" -eq 1 ] && echo '(skipped)' || printf %s "$MW_DIR")"
echo "  mode    : $( [ "$APPLY" -eq 1 ] && echo APPLY || echo DRY-RUN)"
echo

if [ "$APPLY" -eq 1 ]; then
    docker info >/dev/null 2>&1 || die "docker daemon not reachable"
fi

stop_stack

if [ "$SKIP_DB" -eq 0 ]; then
    seed_volume "$DB_DIR" "$DB_VOLUME" "db"
fi
if [ "$SKIP_MW" -eq 0 ]; then
    seed_volume "$MW_DIR" "$MW_VOLUME" "mediawiki"
fi

start_hint
exit 0
