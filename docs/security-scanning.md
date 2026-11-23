# Container security scanning

The Docker build workflow runs Trivy in the `scan` job, in parallel with `deploy-e2e`. The job builds the `linux/amd64` image from the shared registry build cache and scans it using the first comma-separated tag in `needs.tags.outputs.REGISTRY_TAGS`; it does not scan the arm64 image.

The scan reports CRITICAL and HIGH vulnerabilities as `trivy-results.sarif`. The scan sets `ignore-unfixed`, so vulnerabilities without an available fix are not reported. Findings are advisory: the scan uses exit code zero, and scan and SARIF upload errors are allowed to continue without blocking the job. Check the workflow logs for scan or upload failures; missing alerts do not prove the image is free of vulnerabilities.

## Viewing results

Open the repository's **Security > Code scanning** tab and look for the `trivy-container` category. The workflow uploads SARIF on pushes and pull requests from the same repository when a results file exists. Fork pull requests run the scan but skip the upload because their token cannot write security events. Scan logs are available in the Docker build workflow run.

Only users with write access to the repository can open the Code scanning alert list. Read-only contributors can see Code scanning annotations on pull requests.

## Ignore policy

The root [`.trivyignore`](../.trivyignore) starts with comments only. Add entries only after reviewing actual scan findings; prefer a safe package or dependency update when a fix is available.

For each approved ignore, put one CVE ID on its own line. Immediately above it, add a comment recording the affected package, the specific reason for ignoring the finding, and a review date in `YYYY-MM-DD` format. Valid reasons may include no available fix, a package that is unreachable at runtime, or a CVE that does not apply to this image. Support the reason with evidence from the finding and package usage.

Review each entry by its recorded review date. Check whether a fix is now available and whether the rationale still applies; remove the ignore when it is no longer justified. Plain-text comments do not expire ignores automatically, so maintainers must carry out this review. Avoid blanket exclusions.
