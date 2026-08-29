# Taqasta

<p align="center"><img src="https://user-images.githubusercontent.com/592009/198849659-e778c37a-29fb-4f4b-a503-9fd1ee32410a.png" alt="Taqasta" width="600"></p>

Enterprise MediaWiki Docker image with Docker Compose and Kubernetes deployment templates.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/mediawiki?referralCode=hNtFFf&utm_medium=integration&utm_source=template&utm_campaign=generic)

## Philosophy

**Stability first, then quality.** Taqasta serves enterprise wikis that depend on predictable, reproducible images. We pin MediaWiki point releases and extension commits so rebuilds do not silently change behavior. Features matter, but not at the cost of production confidence.

## LTS policy

Taqasta tracks **MediaWiki LTS releases**. The `master` branch follows the current LTS line, with full support through point releases and image updates. When a new LTS ships, the previous LTS continues on a maintenance branch with the same commitment.

For deployments that need an intermediate MediaWiki version, Taqasta may maintain non-LTS branches (e.g. 1.41, 1.42). Those branches receive **unofficial support** only — they are not merged into `master` and do not carry the same commitment as LTS on `master` and REL maintenance branches.

## Canasta fork

This repository is a fork of the MediaWiki application image from the [Canasta](https://github.com/CanastaWiki/Canasta) stack. For the broader Canasta platform, see [Canasta documentation](https://canasta.wiki/) — much of it does not apply to Taqasta.

**Differences from Canasta:**

* Single-wiki focus (no wiki farm)
* Automated wiki installation via environment variables (admin account, database, site settings)
* Template-driven build from [values.yml](values.yml) ([build system docs](docs/build-system.md))
* Image plus reference deployment templates (Docker Compose, Kubernetes) rather than Canasta's full managed stack with CLI and Caddy

## Documentation

| Topic | Location |
|-------|----------|
| Full guide index | [docs/README.md](docs/README.md) |
| Build system | [docs/build-system.md](docs/build-system.md) |
| Extensions (add / update / remove) | [docs/extensions.md](docs/extensions.md) |
| Patching | [docs/patching.md](docs/patching.md) |
| Deployment & runtime | [docs/deployment.md](docs/deployment.md) |
| Upgrades (MW minor, LTS, PHP) | [docs/upgrades/](docs/upgrades/) |
| E2E tests | [e2e/README.md](e2e/README.md) |

## Quick start (local build)

```bash
./validate.sh    # optional: validate values.yml
./compile.sh     # generate Dockerfile from templates
export DOCKER_BUILDKIT=1   # required for Composer secret mounts
./build.sh       # build image locally
```

Extension changes go in [values.yml](values.yml) — see [docs/extensions.md](docs/extensions.md).

## Configuration

### `.htaccess` overrides

See [docs/deployment.md](docs/deployment.md#htaccess-overrides).

## Quality assurance and CI/CD

GitHub Actions validates [values.yml](values.yml), lints the generated Dockerfile, runs the full Playwright e2e suite, and builds multi-platform images on every push and pull request. Images are pushed only after lint, template validation, and the e2e suite pass; the separate PHPUnit `test` job does not gate image pushes.

See [e2e/README.md](e2e/README.md) for running tests locally and debugging CI failures. See [docs/README.md](docs/README.md) for the full documentation index.

## Profiling

The image is bundled with [xhprof](https://www.php.net/manual/en/book.xhprof.php). To enable profiling
ensure that you have `MW_PROFILE_SECRET` environment variable set. Once the variable is set you can
access any page supplying the `forceprofile` GET parameter with the value equal to the `MW_PROFILE_SECRET` to
enable profiling. Doing this enables the following code-block on the settings file:

```php
	$wgProfiler['class'] = 'ProfilerXhprof';
	$wgProfiler['output'] = [ 'ProfilerOutputText' ];
	$wgProfiler['visible'] = false;
	$wgUseCdn = false; // make sure profile is not cached
```

See https://www.mediawiki.org/wiki/Manual:$wgProfiler for details

## Deploy on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/mediawiki?referralCode=hNtFFf&utm_medium=integration&utm_source=template&utm_campaign=generic)

Click the button above to deploy a fully configured Taqasta (MediaWiki) instance on [Railway](https://railway.com/)

The template provisions Taqasta and required services automatically. During setup, you will be prompted to configure environment variables. You can use the defaults and update them later, or change `MW_ADMIN_USER` and `MW_ADMIN_PASS` before the first deployment.

### Post-deploy steps

1. Once the deployment is live, Railway will assign a public URL that you can use to access your wiki
2. Optionally attach a custom domain in the Railway dashboard under **Settings → Networking → Custom Domain** and update `MW_SITE_SERVER` ENV variable in the **Environment Variables** section
3. The wiki installer runs automatically on first boot; after a short initialization you can log in with the admin credentials you configured in `MW_ADMIN_USER` and `MW_ADMIN_PASS`
