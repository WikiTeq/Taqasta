# Taqasta – Agent context

Taqasta is a MediaWiki Docker image and stack (fork of Canasta). This repo contains the image build (templates, `values.yml`, `compile.sh`, `build.sh`), Docker Compose for CI/e2e, and end-to-end tests.

**When editing docs (e.g. README, e2e/README):** Do not use list items in the form `- **Label**: description`. Use plain bullets or inline text instead so lists stay concise and consistent.

- Root: Dockerfile from `Dockerfile.tmpl` via `./compile.sh`; build with `./build.sh`, validate with `./validate.sh`.
- e2e/: Playwright e2e tests; run via `docker compose --profile e2elocal up -d` then `docker compose exec e2e npx playwright test`. See `e2e/README.md`.
- templates/: Dockerfile partials. Extensions/skins in `values.yml`; schema in `values.schema.json`.

CI/CD: GitHub Actions validate, build, run e2e, and push images. See README “Quality Assurance and CI/CD” section.
