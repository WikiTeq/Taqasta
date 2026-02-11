# Taqasta – Agent context

Taqasta is a MediaWiki Docker image and stack (fork of Canasta). This repo contains the image build (templates, `values.yml`, `compile.sh`, `build.sh`), Docker Compose for CI/e2e, and end-to-end tests.

- **Root**: Dockerfile is generated from `Dockerfile.tmpl` via `./compile.sh`. Build: `./build.sh` (after compile). Validate: `./validate.sh`.
- **e2e/**: Playwright e2e tests. Run via Docker: `docker compose --profile e2elocal up -d`, then `docker compose exec e2e npx playwright test`. See `e2e/README.md`.
- **templates/**: Dockerfile partials. **values.yml**: extensions/skins list; **values.schema.json**: schema for values.yml.

CI/CD: GitHub Actions validate, build, run e2e, and push images. See README “Quality Assurance and CI/CD” section.
