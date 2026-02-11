# End-to-End Tests for Taqasta

![Taqasta E2E Banner](taqasta-e2e-banner.png)

This directory contains end-to-end (e2e) tests for the Taqasta MediaWiki Docker stack, built using [Playwright](https://playwright.dev/). These tests verify that a MediaWiki installation is working correctly after deployment.

## Overview

The e2e tests are designed to validate the complete MediaWiki installation and configuration by simulating real user interactions in a browser environment. The tests cover:

- **Installation verification**: Confirms MediaWiki is properly installed
- **User interface elements**: Verifies login, signup, and navigation links
- **Skin and editor functionality**: Tests default skin and visual editor availability
- **API endpoints**: Validates API accessibility
- **Special pages**: Checks version information and software components
- **File uploads**: Tests upload functionality
- **User management**: Validates account creation and admin features

## Test Structure

### Test Files

Test specs live in the **`tests/`** subdirectory. When running Playwright (e.g. from the e2e container), use paths like `tests/001-base.spec.ts`.

- **`tests/001-base.spec.ts`**: Basic functionality tests (installation, login/signup links, skin, editors)
- **`tests/002-edit.spec.ts`**: Page editing and visual editor functionality
- **`tests/003-upload.spec.ts`**: File upload capabilities
- **`tests/004-admin.spec.ts`**: Administrative features and user management
- **`tests/005-createaccount.spec.ts`**: User account creation process

### Configuration Files

- **`playwright.config.ts`**: Playwright test configuration with browser settings, timeouts, and reporting
- **`LocalSettings.php`**: MediaWiki configuration specifically for e2e testing
- **`package.json`**: Node.js dependencies and scripts
- **`Dockerfile`**: Docker container setup for running tests

### Test Fixtures

- **`fixtures/`**: Test assets like sample images for upload testing

## Running Tests

### Option 1: Using Docker Compose (Recommended)

The easiest way to run e2e tests is through Docker Compose, which handles all dependencies automatically.

#### Prerequisites
- Docker and Docker Compose
- BuildKit enabled (`export DOCKER_BUILDKIT=1`)
- Git (for cloning extensions during build)

```bash
# Enable BuildKit for advanced Docker features (required)
export DOCKER_BUILDKIT=1

# Compile the Dockerfile template
./compile.sh

# Start the full stack including the e2e test container
docker compose --profile e2elocal up -d

# Wait for the web (Taqasta) container to be healthy, then run the tests
docker compose exec e2e npx playwright test

# View test results (run report server, then open http://localhost:9323)
docker compose exec e2e npx playwright show-report --host 0.0.0.0
```

**Note**: BuildKit must be enabled for the Docker build process. If you encounter build errors, ensure `DOCKER_BUILDKIT=1` is set.

### Option 2: Development and debugging

For developing or debugging tests, use the same Docker setup: run Taqasta with the `e2elocal` profile (which starts the web stack plus a Node container with Playwright). Then run tests inside the e2e container:

```bash
# From repo root: ensure stack is up and web is healthy, then:
docker compose exec e2e npx playwright test

# Run a single test file
docker compose exec e2e npx playwright test tests/001-base.spec.ts

# Run with browser visible (headed) or step-through debug
docker compose exec e2e npx playwright test --headed
docker compose exec e2e npx playwright test tests/001-base.spec.ts --debug

# Open a shell in the e2e container to run ad-hoc commands
docker compose exec e2e sh
```

## Configuration

### Environment Variables

The tests adapt their configuration based on the environment:

- **`TAQASTA_E2E_IN_DOCKER=true`**: When running in the e2e container (Docker), uses internal networking (`http://web:80/`)

### Browser Configuration

Tests run on Chromium by default with the following settings:
- **Navigation timeout**: 60 seconds
- **Test timeout**: 5 minutes
- **Global timeout**: 60 minutes
- **Screenshots**: Captured only on failure
- **Traces**: Retained on failure for debugging

## MediaWiki Test Configuration

The `LocalSettings.php` file contains MediaWiki-specific settings for testing:

- Enables uploads for anonymous users
- Loads essential extensions (ParserFunctions, Scribunto, VisualEditor)
- Configures Vector skin as default
- Disables beta welcome popup for VisualEditor
- Sets up cache and security settings appropriate for testing

## Debugging

### Viewing Test Results

After running tests, view the report from inside the e2e container:

```bash
docker compose exec e2e npx playwright show-report --host 0.0.0.0
```

Then open http://localhost:9323 in your browser.

### Running Tests in Debug Mode

```bash
# Run with browser visible
docker compose exec e2e npx playwright test --headed

# Run with step-through debugging
docker compose exec e2e npx playwright test tests/001-base.spec.ts --debug
```

## Test Coverage

The current test suite covers:

* ✅ MediaWiki installation verification
* ✅ User authentication UI elements
* ✅ Default skin (Vector) functionality
* ✅ Visual Editor availability
* ✅ Anonymous editing capabilities
* ✅ Special pages (Version, API)
* ✅ File upload functionality
* ✅ User account creation
* ✅ Administrative features

## Adding New Tests

When adding new test files:

1. Follow the naming convention: `NNN-description.spec.ts`
2. Use descriptive test names
3. Include appropriate assertions
4. Add comments for complex test logic
5. Update this README if adding new test categories

## CI/CD Integration

These e2e tests are **fully integrated** into Taqasta's GitHub Actions CI/CD pipeline as a **mandatory quality gate**. The tests automatically run against every code change and **must pass** before Docker images are built and deployed.

### Key Integration Points

- **Automatic Execution**: Tests run on every push, pull request, and tag
- **Quality Gate**: Build pipeline stops if e2e tests fail
- **E2E runs on AMD64 (x86_64)**: Tests execute against the x86_64 image build
- **Failure Reporting**: Playwright test reports (and screenshots) uploaded to GitHub Pages

### CI/CD Test Environment

When running in CI/CD, the tests use:
- **Base URL**: `http://web:80/` (internal Docker networking)
- **Database**: MySQL 8.0 container
- **MediaWiki**: Pre-configured with test-specific LocalSettings.php
- **Browser**: Chromium in headless mode
- **Timeout**: 5 minutes per test, 60 minutes total

For detailed information about the CI/CD pipeline structure, quality assurance flow, and debugging CI/CD failures, see the main [`README.md`](../README.md#quality-assurance-and-cicd).

## Troubleshooting

### Docker Compose Build Issues

#### BuildKit Not Enabled
**Error**: `the --mount option requires BuildKit`
**Solution**: Enable BuildKit before running Docker Compose:

```bash
export DOCKER_BUILDKIT=1
docker compose --profile e2elocal up -d
```

To make this permanent, add `DOCKER_BUILDKIT=1` to your shell profile (`.bashrc`, `.zshrc`, etc.).

#### Missing Dockerfile
**Error**: `unable to prepare context: unable to evaluate symlinks in Dockerfile path: lstat .../Dockerfile: no such file or directory` (or similar, with your repo path)
**Solution**: Compile the Dockerfile template first:

```bash
./compile.sh
docker compose --profile e2elocal up -d
```

### Tests fail or connection errors

#### Connection refused / page not loading
**Error**: `page.goto: net::ERR_CONNECTION_REFUSED` or similar when running tests in the e2e container.

**Solution**: The web (Taqasta) container may not be ready yet. Wait for it to be healthy after `docker compose --profile e2elocal up -d` (e.g. 30–60 seconds), or check with `docker compose ps` and ensure the web service is healthy before running `docker compose exec e2e npx playwright test`.
