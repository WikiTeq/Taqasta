# Build system

Taqasta uses [gomplate](https://gomplate.ca/) to generate the Dockerfile and Composer config from templates and [values.yml](../values.yml).

## Key files

| File | Role |
|------|------|
| [values.yml](../values.yml) | Extensions, skins, Composer packages, repositories, patches |
| [values.schema.json](../values.schema.json) | JSON Schema for validating [values.yml](../values.yml) |
| [Dockerfile.tmpl](../Dockerfile.tmpl) | Main Dockerfile template |
| [templates/](../templates/) | Per-stage Dockerfile partials (`base`, `core`, `extensions`, `skins`, `composer`, …) |
| [_sources/configs/composer.wikiteq.json.tmpl](../_sources/configs/composer.wikiteq.json.tmpl) | Composer merge config template |
| [.gomplate.yml](../.gomplate.yml) | Gomplate inputs and [values.yml](../values.yml) datasource |
| [compile.sh](../compile.sh) | Generates `Dockerfile` and [_sources/configs/composer.wikiteq.json](../_sources/configs/composer.wikiteq.json) |
| [validate.sh](../validate.sh) | Validates [values.yml](../values.yml) against the schema (via Docker + `ajv`) |
| [build.sh](../build.sh) | Runs a local multi-platform Docker image build with buildx |

Generated artifacts (`Dockerfile`, [_sources/configs/composer.wikiteq.json](../_sources/configs/composer.wikiteq.json)) are gitignored. CI runs [validate.sh](../validate.sh) and [compile.sh](../compile.sh) before every build.

## Workflow

1. Edit [values.yml](../values.yml) (and templates if needed).
2. Run `./validate.sh` to check YAML against the schema.
3. Run `./compile.sh` to generate the Dockerfile and Composer files.
4. Build locally with `./build.sh` or open a PR and let GitHub Actions build the image.

On Windows with Git Bash, if path conversion breaks these scripts, set `MSYS_NO_PATHCONV=1` before running `./validate.sh`, `./compile.sh`, or `./build.sh`.

## Extension stages and cache

Non-bundled extensions from [values.yml](../values.yml) are grouped into Docker stages of **30 extensions each** ([templates/extensions.Dockerfile](../templates/extensions.Dockerfile)). Stages are combined in the `composer` stage, where extension patches are applied.

Reordering extensions in [values.yml](../values.yml) can invalidate stage caches because stage boundaries follow list order. Prefer appending new extensions at the end when possible.

## Schema reference

Field definitions for extension entries (repository, branch, commit, `bundled`, `additional steps`, Wikidata ID, etc.) are documented in [values.schema.json](../values.schema.json).
