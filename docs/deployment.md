# Deployment and runtime configuration

## Baking vs enabling extensions

| Layer | Mechanism | Where |
|-------|-----------|--------|
| **Bake into image** | [values.yml](../values.yml) → gomplate build | This repository |
| **Enable on a wiki** | `wfLoadExtension()` in `LocalSettings.php` | Wiki deployment configuration |
| **Legacy env enable** | `MW_LOAD_EXTENSIONS` intersected with `DOCKER_EXTENSIONS` | Deprecated; use [values.yml](../values.yml) and per-wiki `LocalSettings.php` instead |

Adding an extension to [values.yml](../values.yml) puts files in the image. It does **not** enable the extension on any wiki. Enable it per wiki by adding `wfLoadExtension()` (and any required config) to that wiki's `LocalSettings.php` or equivalent deployment configuration.

The `DOCKER_EXTENSIONS` constant in [_sources/canasta/DockerSettings.php](../_sources/canasta/DockerSettings.php) is a legacy allowlist for `MW_LOAD_EXTENSIONS`. It is not updated by [values.yml](../values.yml) today. New work should use `LocalSettings.php`; the env-based path may be removed in a future cleanup.

## Environment variables

Taqasta reads many settings from environment variables (admin account, database, site URL, uploads, email, etc.). See [docker-compose.sample.yml](../docker-compose.sample.yml) for examples.

CI and local e2e stacks use [.env.ci](../.env.ci). Copy it to `.env` before running `docker compose` (see [e2e/README.md](../e2e/README.md)).

### Non-prod visual indicator

Set `MW_SHOW_NON_PROD_INDICATOR` to `true` to show a red frame and a NOT PRODUCTION label on every page. The default value is off.

You can also set `$wgWikiTeqNonProdIndicator` to `true` in the site `LocalSettings.php` file. Do not enable this on a production wiki.

Click the label to hide the frame and the label for 20 seconds on the current page. A new page load shows the overlay again.

### WikiTeq hosted-wiki policy footer

Set `ENABLE_WIKITEQ_POLICY_FOOTER_LINK` to `true` (or `1`) to add a footer link to WikiTeq's hosted-wiki legal page. The native MediaWiki Privacy policy link is not changed.

Defaults:

- Label: `WikiTeq Terms & Privacy`
- URL: `https://wikiteq.com/hosted-wiki-legal`

Optional overrides: `WIKITEQ_POLICY_FOOTER_LINK_LABEL`, `WIKITEQ_POLICY_FOOTER_LINK_URL`.

## Compose and Kubernetes templates

| Path | Purpose |
|------|---------|
| [docker-compose.yml](../docker-compose.yml) | CI / E2E stack (not for production use as-is) |
| [docker-compose.sample.yml](../docker-compose.sample.yml) | Local development reference |
| [docker-compose.apache.yml](../docker-compose.apache.yml) | Rollback override: run the bundled Apache instead of nginx + php-fpm |
| [main/kubernetes/](../main/kubernetes/) | Example Kubernetes manifests (wiki, runjobs, mysql, …) |

## Web server: external Nginx vs bundled Apache

Since WIK-2139 the default stack serves HTTP with a dedicated `nginx` container
(`nginx:alpine`) instead of the Apache instance bundled in the web image:

- The `web` container runs php-fpm on port 9000 (`/run-apache-fpm.sh`). Its
  entrypoint performs the same bootstrap as before (volume sync, permissions,
  settings check, maintenance scripts); only the server start differs.
- The entrypoint mirrors the document root into `$MW_VOLUME/docroot`
  (`/mediawiki/docroot` inside the volume), so nginx can serve static files
  from the same content. Wiki code updates are re-synced into the mirror.
- The nginx configuration lives in `_sources/configs/nginx/` and replicates
  the previous Apache behavior: short URLs through `/w/index.php`, artificial
  `robots.txt`, `.git` 404s, `/server-status` from localhost, maintenance-mode
  503 while `.maintenance` exists, one-year expiry headers for static assets,
  and `client_max_body_size` matching the PHP upload limits. Only MediaWiki
  entry points (`index`, `load`, `api`, `rest`, `img_auth`, …) are passed to
  php-fpm; any other `.php` request is answered with 404.
- In Compose the upstream is configured via `NGINX_UPSTREAM` (default
  `web:9000`) and the body size limit via `NGINX_CLIENT_MAX_BODY_SIZE`.

### Rolling back to the bundled Apache

The image still contains Apache; restore the previous stack behavior by
adding the override file:

```bash
docker compose -f docker-compose.sample.yml -f docker-compose.apache.yml up -d
```

This runs `/run-apache.sh` in the `web` container again and drops the nginx
service. It requires Docker Compose v2.24+ (for the `!override` YAML tags);
with older versions remove the `nginx` service and set
`command: /run-apache.sh` plus the port mapping manually.

## `.htaccess` overrides

The image ships a default `.htaccess` at `/var/www/mediawiki/.htaccess`.

- **Replace entirely:** mount to `/var/www/mediawiki/.htaccess`
- **Override wiki rules only:** mount to `/var/www/mediawiki/w/.htaccess`

Example docker-compose configuration:

```yaml
volumes:
  # Replace entire file at DocumentRoot
  - ./my-custom-htaccess:/var/www/mediawiki/.htaccess
  # OR override wiki subdirectory only (preserves base config)
  - ./my-custom-htaccess:/var/www/mediawiki/w/.htaccess
```

Test custom rules after image upgrades.

## Image tags

GitHub Actions assigns tags when building images:

| Build type | Tag format | Example |
|------------|------------|---------|
| **PR** (testing) | `MW_CORE_VERSION-YYYYMMDD-<PR_NUMBER>` | `1.43.8-20260717-405` |
| **master** (production) | `latest` | `latest` |
| **master** (production) | `VERSION` (from [VERSION](../VERSION)) | `1.3.1-pre` |
| **master** (production) | `MW_MAJOR_VERSION-latest` | `1.43-latest` |
| **master** (production) | `MW_CORE_VERSION-latest` | `1.43.8-latest` |
| **master** (production) | `MW_CORE_VERSION-YYYYMMDD-<short-sha>` | `1.43.8-20260717-d562a4b` |

Use PR tags for testing; use tags from `master` or the applicable LTS maintenance branch for production deployments.

## Profiling

See [README profiling section](../README.md#profiling) for xhprof setup (`MW_PROFILE_SECRET`, `forceprofile` parameter, and profiler settings).
