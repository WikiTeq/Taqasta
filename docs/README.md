# Building and maintaining the Taqasta image

Canonical documentation for building and maintaining the Taqasta Docker image lives in this directory.

Extensions, skins, and patches are defined in [values.yml](../values.yml).

## Guides

| Topic | Document |
|-------|----------|
| Build system ([values.yml](../values.yml), gomplate, validate/compile) | [build-system.md](build-system.md) |
| Adding, updating, and removing extensions | [extensions.md](extensions.md) |
| Applying patches | [patching.md](patching.md) |
| Deployment, env vars, enabling extensions | [deployment.md](deployment.md) |
| Minor MediaWiki point releases | [upgrades/mediawiki-minor.md](upgrades/mediawiki-minor.md) |
| LTS MediaWiki upgrades | [upgrades/mediawiki-major.md](upgrades/mediawiki-major.md) |
| PHP version upgrades | [upgrades/php.md](upgrades/php.md) |
| End-to-end tests (Playwright) | [../e2e/README.md](../e2e/README.md) |

## LTS policy

Taqasta tracks **MediaWiki LTS releases** on `master` and LTS maintenance branches. Non-LTS branches may exist with unofficial support only. See the [LTS policy](../README.md#lts-policy) in the repository README.

## Philosophy

Taqasta prioritizes **stability**, then **quality**. Images pin extension commits and MediaWiki point releases so enterprise deployments get predictable, reproducible builds. See the [repository README](../README.md) for the overview.
