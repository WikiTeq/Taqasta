# Container security scanning

The Docker build workflow runs Trivy in the `deploy-e2e` job after `Build and load`, before the e2e environment starts. It scans the locally loaded `linux/amd64` image using the first comma-separated tag in `needs.tags.outputs.REGISTRY_TAGS`; it does not build another image or scan the arm64 image.

The scan reports CRITICAL and HIGH vulnerabilities as `trivy-results.sarif`, including vulnerabilities without a fix. Findings are advisory: the scan uses exit code zero, and scan and SARIF upload errors are allowed to continue without blocking the job. Check the workflow logs for scan or upload failures; missing alerts do not prove the image is free of vulnerabilities.

## Viewing results

Open the repository's **Security > Code scanning** tab and look for the `trivy-container` category. The workflow uploads SARIF on pushes and pull requests from the same repository when a results file exists. Fork pull requests run the scan but skip the upload because their token cannot write security events. Scan logs are available in the Docker build workflow run.

Code scanning alerts in a public repository are public. This workflow does not make findings private.

## Ignore policy

The root [`.trivyignore`](../.trivyignore) starts with comments only. Add entries only after reviewing actual scan findings; prefer a safe package or dependency update when a fix is available.

For each approved ignore, put one CVE ID on its own line. Immediately above it, add a comment recording the affected package, the specific reason for ignoring the finding, and a review date in `YYYY-MM-DD` format. Valid reasons may include no available fix, a package that is unreachable at runtime, or a CVE that does not apply to this image. Support the reason with evidence from the finding and package usage.

Review each entry by its recorded review date. Check whether a fix is now available and whether the rationale still applies; remove the ignore when it is no longer justified. Plain-text comments do not expire ignores automatically, so maintainers must carry out this review. Avoid blanket exclusions and do not enable `ignore-unfixed` without a separate decision.

The first real scan and vulnerability triage are still required. No CVEs have been ignored yet.
