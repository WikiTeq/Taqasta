# LTS MediaWiki upgrades

Each time a new LTS version of MediaWiki is released, we need to update the Taqasta image to load that new version. You will also want to create a new branch for the previous LTS so we can continue updating it for deployments still on that version. For the quarterly minor updates, see [mediawiki-minor.md](mediawiki-minor.md).

Taqasta's `master` branch currently tracks MediaWiki 1.43 LTS. This guide describes what to do when the next LTS is released (for example MediaWiki 1.47): branch the old LTS, update core, extensions, and CI.

Extensions, skins, and Composer packages are defined in [values.yml](../../values.yml). See [build-system.md](../build-system.md) for how the build works. Example commits and pull requests linked below are from the 1.39 → 1.43 upgrade; use them as reference only.

## Branch previous LTS

When the next LTS is released (for example MediaWiki 1.47) and you upgrade `master` to track it, create a maintenance branch for the previous LTS so Taqasta can keep shipping image updates for deployments that have not upgraded yet.

Before merging the upgrade on `master`:

1. Create a branch named for the previous LTS (for a 1.43 → 1.47 upgrade, `REL1_43`) from `master` as it exists immediately before the upgrade.
2. Continue supporting point releases and extension changes on that branch for as long as deployments still run that LTS.
3. Update CI so the new branch provides post-merge build images, following the same pattern as existing LTS maintenance branches.

Example from the 1.39 → 1.43 upgrade (creating the previous-LTS branch): [REL1_39 branch setup](https://github.com/WikiTeq/Taqasta/commit/f315ce981cc9df3358fbc2b37c64dab583c6ec11).

Older example of CI workflow changes for a maintenance branch (from the `REL1_35` era; that commit also contains other changes — focus on [.github/workflows/docker-image.yml](../../.github/workflows/docker-image.yml)): [REL1_35 CI workflow](https://github.com/WikiTeq/Taqasta/commit/3381fa47f5daf265caf5edcbe51917857f4ca950).

## Verify PHP

Make sure that the version of PHP in the Taqasta image is supported by the new release of MediaWiki. If not, you'll need to update PHP — instructions for doing that are available at [php.md](php.md). Compatibility is documented on the [MediaWiki PHP version matrix](https://www.mediawiki.org/wiki/Special:MyLanguage/Support_policy_for_PHP/Tables) and follows the support policy on [Support policy for PHP](https://www.mediawiki.org/wiki/Special:MyLanguage/Support_policy_for_PHP).

## Update Core

In the [templates/base.Dockerfile](../../templates/base.Dockerfile) template, update the environmental variables `MW_VERSION` and `MW_CORE_VERSION` for the new version:

```diff
- ENV MW_VERSION=REL1_43 \
- 	MW_CORE_VERSION=1.43.8 \
+ ENV MW_VERSION=REL1_47 \
+ 	MW_CORE_VERSION=1.47.0 \
 	WWW_ROOT=/var/www/mediawiki \
 	MW_HOME=/var/www/mediawiki/w \
```

## Update bundled extensions

Review the changes in what extensions were bundled between the previous LTS and the new one. There should be tasks under the various `MW-1.XX-release` projects in Phabricator.

Update the list of bundled extensions — if the extension was previously included in Taqasta, remove the original entry from [values.yml](../../values.yml) and then, if applicable, add an updated entry to the section at the top with the bundled extensions.

In [values.yml](../../values.yml) for bundled extensions we:

- do not list bundled extensions that do not have composer dependencies
- list bundled extensions that have composer dependencies, with the additional step documented (see below) but without a commit to check out because the extension version is based on the bundled version

```yaml
  - AbuseFilter:
      Wikidata ID: Q134589302
      bundled: true
      additional steps:
        - composer update
```

## Update extensions and skins

After processing the bundled extensions, update the list of commits to check out for the remaining extensions. The following rules serve as a good starting point:

- If the extension was tracking a version branch (e.g. `REL1_43`) in Gerrit, update to the latest commit of the new version branch (e.g. `REL1_47`). If the YAML does not specify a branch explicitly then the version branch is assumed.
- If the extension was pinned to a specific released version of an extension, e.g. version 4.1, update to the latest released version.
- If the extension does not have version-specific branches (e.g. is not hosted on Gerrit) update to the latest commit of the primary branch.
- If the extension has a Gerrit patch applied, make sure to upgrade to a version that has that patch merged, or otherwise make sure the patch is still present if needed.

Review extension patches in [values.yml](../../values.yml) `patches:` — for those that are still relevant, ensure that the patch file still applies, or rebase it if needed. See [patching.md](../patching.md). Also review manually-applied core and skin patches in [templates/core.Dockerfile](../../templates/core.Dockerfile) and [templates/skins.Dockerfile](../../templates/skins.Dockerfile).

Before merging, confirm extensions listed in [values.yml](../../values.yml) are compatible with the new MediaWiki version and update pinned commits or versions as needed.

## Update psysh

You may also need to update the `psy/psysh` composer constraint to match the constraint in the new version of MediaWiki. Failure to do so may lead to the image failing to build, either immediately or after additional versions of `psy/psysh` are released. Locate the constraint to use in the `require-dev` section of core's `composer.json`, and update Taqasta's [values.yml](../../values.yml) accordingly if the values are different.

## Other tips

The docker build error logs are your friend — read the details of what went wrong! If you are having trouble understanding the output, consider generating the docker file locally (`MSYS_NO_PATHCONV=1 ./compile.sh` in the Taqasta clone; see [compile.sh](../../compile.sh)) to better understand the step that went wrong. You can also build the image locally as you experiment with changes. Sometimes errors are just flukes, like being unable to connect to some remote resource.

Sometimes a deployment needs a non-LTS version — in that case, the steps are essentially the same, except that the changes are not going to be merged into `master`, which continues tracking the current LTS. Non-LTS branches receive [unofficial support only](../../README.md#lts-policy). Set up CI for the new branch. See the example pull requests below.

## Resources

You may find it useful to consult pull requests from earlier MediaWiki upgrades.

These pull requests are from earlier MediaWiki upgrades; workflow and file layout may have changed since then. Prefer the steps in this guide and [build-system.md](../build-system.md) over copying older PRs verbatim.

- [MW 1.39 → 1.43](https://github.com/WikiTeq/Taqasta/pull/231) — example from the 1.39 → 1.43 upgrade (most recent LTS upgrade)
- [MW 1.39 → 1.42](https://github.com/WikiTeq/Taqasta/pull/211) — example from the 1.39 → 1.42 upgrade; non-LTS, for PR-based image builds
- [MW 1.39 → 1.41](https://github.com/WikiTeq/Taqasta/pull/163) — example from the 1.39 → 1.41 upgrade; likewise for PR-based image builds
