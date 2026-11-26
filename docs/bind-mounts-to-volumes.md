# Migrating writable bind mounts to Docker named volumes (WIK-2057)

All writable Taqasta state now lives in **Docker named volumes** instead of host bind-mount directories:

| Data | Named volume | Was (legacy layout) |
|------|--------------|---------------------|
| MySQL datadir | `taqasta_db_data` | `./mysql` bound to `/var/lib/mysql` |
| MediaWiki volume (uploads, images, config) | `taqasta_mw_volume` | `./images` and friends |

Read-only configuration files (custom `LocalSettings`, `.htaccess` overrides, dev log viewers) intentionally remain bind mounts — they are not writable state and are versioned with your deployment.

## Why

Bind-mounted directories caused recurring ownership mismatches between the container user and the host user, permission drift after image upgrades, and inconsistent behavior between hosts. Named volumes fix these issues ([WIK-476](https://wikiteq.atlassian.net/browse/WIK-476), [WIK-2057](https://wikiteq.atlassian.net/browse/WIK-2057)), keep data persistent across container restarts and rebuilds, and make deployments more portable.

Kubernetes deployments are **unaffected**: they use `PersistentVolumeClaim`s and were already volume-based.

## What changes for existing VPS clients

If your deployment stores the database or wiki data in host directories that are bind-mounted into containers, do a one-time migration when adopting the updated compose files. Until the data is copied into the named volumes, switching compose files would start with *empty* volumes.

The repository ships an idempotent migration tool: [`scripts/migrate-binds-to-volumes.sh`](../scripts/migrate-binds-to-volumes.sh).

### Upgrade steps

1. **Back up** (as you would before any upgrade): `mysqldump` plus a file-level copy of the images directory.
2. Pull the updated Taqasta files, then run a dry run from the deployment directory:

   ```bash
   sh scripts/migrate-binds-to-volumes.sh
   ```

   It prints what it would migrate (file counts and byte totals) and changes nothing.
3. Review the plan, then apply it:

   ```bash
   sh scripts/migrate-binds-to-volumes.sh --apply
   ```

   The script stops the stack (`docker compose stop`; containers are kept), seeds the `taqasta_db_data` / `taqasta_mw_volume` volumes from the legacy directories using a temporary helper container, verifies file counts and byte totals against the source, and renames each migrated directory to `<name>.migrated-<timestamp>`; nothing is ever deleted (apply mode only; a dry run neither stops services nor touches disk).
4. Start the stack on the new compose files:

   ```bash
   docker compose -f docker-compose.sample.yml up -d
   ```

5. Smoke-test the wiki (login, page edit, file upload). Keep the `*.migrated-<timestamp>` directories until you are satisfied; they double as the rollback snapshot.

Useful options: `-f FILE` for custom compose files (repeatable), `-p NAME` for a specific project name, `--db-dir DIR` / `--mw-dir DIR` if your legacy directories are not at `./mysql` / `./images`, and `--skip-db` / `--skip-mw` to migrate only one of them. Set `TAQASTA_DB_VOLUME` / `TAQASTA_MW_VOLUME` if your deployment overrides the volume names.

### Rollback

Stop the stack, point compose back at the previous file (the one using bind mounts), rename `<name>.migrated-<timestamp>` back to `<name>` if needed, and start the stack. The named volumes can be removed later once the rollback window closes.

## Notes

- The migration runs entirely on the client server by the client/operator; WikiTeq does not run anything remotely as part of this change.
- The helper container uses `rsync` when available and falls back to `cp -a`. Re-runs never overwrite existing files in a volume, so interrupted migrations can simply be re-run.
- Fresh installs have nothing to migrate: new stacks create empty named volumes on first start.
- The volume names are pinned literals in the compose files (`taqasta_db_data`, `taqasta_mw_volume`), not `${VAR:-default}` interpolations, so operators running multiple stacks on one host must edit the YAML to rename them per deployment.
