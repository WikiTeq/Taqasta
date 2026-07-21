# Patching

[Taqasta](https://github.com/WikiTeq/Taqasta) is a docker image that contains many extensions pre-installed and available for use. However, sometimes we may want to apply a patch to the extensions that we install while we wait for the patch to get merged in the upstream repo (or indefinitely, for patches that are not intended to be sent upstream).

Extension and patch definitions live in [values.yml](../values.yml). See [build-system.md](build-system.md) for how the build system uses that file.

Note that patches should be used sparingly, and removed once the upstream repo has been updated (see [Updating extensions](extensions.md#updating)). Each patch presents another potential point of confusion when debugging, since the code that is running in the image will not match what the upstream repo includes.

## Creating a patch file

The first step to adding a patch to Taqasta is to generate the patch locally. Based on the version of the applicable repository currently loaded by Taqasta, make the changes needed, and create a git commit. Then, use the command `git format-patch HEAD^ --stdout > patch-file-name.patch`, replacing `patch-file-name` with the desired name.

## Extension patches (preferred)

Extension patches are declared in [values.yml](../values.yml):

```yaml
patches:
  - name: FlexDiagrams.0.4.fix.diff
    path: extensions/FlexDiagrams
```

- `name` — file in [_sources/patches/](../_sources/patches/)
- `path` — directory under `$MW_HOME` where `git apply` runs (extensions only; schema pattern `extensions/ExtensionName`)

After the patch file has been created, add it to the [_sources/patches/](../_sources/patches/) directory of the Taqasta repo, and add a `patches:` entry in [values.yml](../values.yml). Gomplate generates `COPY` and `git apply` steps in [templates/composer.Dockerfile](../templates/composer.Dockerfile) before `.git` directories are removed.

## Core and skin patches

Core and skin patches are declared directly in stage templates (not in [values.yml](../values.yml)):

| Patch file | Template |
|------------|----------|
| `core-local-settings-generator.patch` | [templates/core.Dockerfile](../templates/core.Dockerfile) |
| `core-rest-request-uri-psr7.patch` | [templates/core.Dockerfile](../templates/core.Dockerfile) |
| `skin-refreshed.patch` | [templates/skins.Dockerfile](../templates/skins.Dockerfile) |
| `skin-refreshed-737080.diff` | [templates/skins.Dockerfile](../templates/skins.Dockerfile) |

`skin-refreshed.patch` is applied with `patch -u`; the other core and skin patches use `git apply` (see [templates/skins.Dockerfile](../templates/skins.Dockerfile)).

To add or update a core or skin patch: edit the relevant template with `COPY` and apply steps before `.git` cleanup, and place the patch file in [_sources/patches/](../_sources/patches/).

## Cleanup

When updating an extension, check whether Taqasta patches are still needed. Delete obsolete patch files and `patches:` entries together.
