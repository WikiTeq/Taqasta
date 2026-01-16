# Taqasta

![taqasta (1)-min](https://user-images.githubusercontent.com/592009/198849659-e778c37a-29fb-4f4b-a503-9fd1ee32410a.png)

A full-featured MediaWiki stack for easy deployment of enterprise-ready MediaWiki on production environments.

Note: This repo is a fork of the MediaWiki application Docker image included in the Canasta stack.
For complete documentation on the overall Canasta tech stack, including installation instructions,
please visit https://github.com/CanastaWiki/Canasta-Documentation. Note,
however, that parts of that documentation do not apply to using Taqasta.

# Differences from Canasta

While this repo is a fork of Canasta and shares substantial similarities, there
are a number of places where Taqasta's behavior differents from Canasta's

* Taqasta bundles a lot more extensions and skins, allowing you to enable them
on your wiki without needing to download them separately.
* Taqasta does not support running multiple wikis at the same time as a farm.
* Taqasta makes much greater use of environmental variables to read
configuration, which can be used for everything from enabling email and upload
to adding extensions and skins.
* Taqasta also uses environmental variables to allow configuring the admin and
database accounts, allowing the installer to run as part of the container
setup rather than needing to install the wiki manually - with Canasta, you
need to manually go through the MediaWiki installation process, while Taqasta
will perform it automatically. This is especially helpful if you want to copy
the configuration of an existing wiki.

## Build System

Taqasta uses a template-based build system powered by [gomplate](https://gomplate.ca/) (Go templates) to generate the
Dockerfile and configuration files:

* The `Dockerfile` and `_sources/configs/composer.wikiteq.json` are compiled from `Dockerfile.tmpl` and `_sources/configs/composer.wikiteq.json.tmpl` using the `compile.sh` script
* Dockerfile partials are organized in the `templates/` directory
* The list of extensions and skins bundled into the image is controlled by the `values.yml` file

To build the image, run the `compile.sh` script first to generate the final Dockerfile and configuration files from
their templates, then proceed with the normal Docker build process. You can use shortcut `build.sh` to build the image
locally.

**Note**: The build process requires BuildKit to be enabled due to advanced Docker features used in the image:

```bash
export DOCKER_BUILDKIT=1
./build.sh
```

Note that the WikiTeq team, which maintains Taqasta, also maintains a dedicated
branch of Canasta that is much more closely aligned with Canasta but includes
various extensions and other tweaks that the WikiTeq team uses.

## Configuration

### Extending or Overriding .htaccess

The Taqasta image includes a default `.htaccess` file at `/var/www/mediawiki/.htaccess` with MediaWiki-specific rewrite rules and caching directives. If you need to customize Apache configuration, you can mount your own `.htaccess` file at different directory levels depending on your needs:

**To completely replace the base configuration** (replace all rules in the default file):
- Mount your `.htaccess` file to `/var/www/mediawiki/.htaccess` (DocumentRoot)
- This will completely replace the default `.htaccess` file

**To override specific settings** (replace rules in the base file):
- Mount your `.htaccess` file to `/var/www/mediawiki/w/.htaccess` (subdirectory)
- This file will take precedence over the base `.htaccess` for requests to the wiki directory

**Important Notes:**
- Mounting a file directly to `/var/www/mediawiki/.htaccess` will completely replace the default file, which may break functionality during image updates
- For subdirectory-specific overrides, use the `/var/www/mediawiki/w/.htaccess` approach to preserve the base configuration
- Always test your custom `.htaccess` rules after updating the Taqasta image to ensure compatibility

Example docker-compose configuration:
```yaml
volumes:
  # To replace: mount to DocumentRoot (replaces entire file)
  - ./my-custom-htaccess:/var/www/mediawiki/.htaccess
  # OR to override: mount to subdirectory (preserves base config)
  - ./my-custom-htaccess:/var/www/mediawiki/w/.htaccess
```

## Notes on Dockerfile structure

The extensions sources from the values.yml are grouped into individual stages (30 per stage)
to allow for better cache use and allowing parallel build. Later under the `composer` stage
the extensions stages results are combined into one extensions directory and extensions patches
(if any) are applied.

While this allows for faster builds and better cache use this also may lead to accidental stages
caches invalidations if the order of the extensions in the values.yml is changed as the stages
are created by groups of thirty extensions, following the natural order as they appear in the `values.yml`.

# Adding Extensions

To add a new extension to the Taqasta image:

1. Open `values.yml` in the root directory
2. Add a new entry under the `extensions` section following YAML schema format (`values.schema.json`)
3. Run `./validate.sh` to verify that the YAML file is valid against the schema
4. Run `./compile.sh` to verify that your addition has a valid syntax
5. Either run `./build.sh` to build the updated image locally or push your change to remote branch to build using CI

See `values.schema.json` for fields definitions.

# Quality Assurance and CI/CD

Taqasta uses GitHub Actions for automated quality assurance and deployment. The CI/CD pipeline validates code quality, runs comprehensive tests, and delivers production-ready Docker images.

## Pipeline Jobs

**Lint & Validate** → **Generate Tags** → **Build & Test** → **Push Images** → **Merge Manifests** → **Notify**

## Testing Strategy

Automated e2e tests with Playwright validate:
- MediaWiki installation and setup
- User interface and authentication
- Editor functionality
- API endpoints and file uploads

See [`e2e/README.md`](e2e/README.md) for detailed testing information.

## Validation Gates

- **Syntax Check**: YAML validation and Dockerfile linting
- **Build Success**: Multi-platform Docker compilation
- **Functional Tests**: Full e2e test suite
- **Deployment**: Images only pushed after all validations pass

## Automation

Pipeline runs automatically on:
- Push to master branch
- Pull requests
- Tag creation

## Benefits

- Zero broken deploys
- Cross-platform validation (AMD64/ARM64)
- Automated feedback with diagnostics
- Consistent testing environment

# Submitting changes back to Canasta

1. Ensure your local version of repo has `upstream` set to the Canasta repo:

```bash
git remote -v
# if upstream is missing, add it
git remote add upstream git@github.com:CanastaWiki/Canasta.git
```

2. Switch to `origin/canasta` branch

```bash
git fetch origin
git fetch upstream
git checkout canasta
```

3. Update the branch by merging Canasta repo changes into the `canasta` branch

```bash
git merge upstream/master
```

4. Create a new branch for your changes

```bash
git checkout -b fork/name-of-my-change
```

4. Cherry-pick desired change into just created `fork/name-of-my-change` branch

```bash
git cherry-pick <commit-hash>
```

5. Push the `fork/name-of-my-change` branch changes to this repo

```bash
git push origin canasta
```

6. Create PR from this repo back to Canasta repo

https://github.com/WikiTeq/Taqasta/pulls , ensure that you have `CanastaWiki/Canastas:master` choosen as base,
and `WikiTeq/Taqasta:fork/name-of-my-change` as compare.

# Profiling

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
