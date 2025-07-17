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
locally

Note that the WikiTeq team, which maintains Taqasta, also maintains a dedicated
branch of Canasta that is much more closely aligned with Canasta but includes
various extensions and other tweaks that the WikiTeq team uses.

## Notes on Dockerfile structure

The extensions sources from the values.yml are grouped into individual stages (10 per stage)
to allow for better cache use and allowing parallel build. Later under the `composer` stage
the extensions stages results are combined into one extensions directory and extensions patches
(if any) are applied

While this allows for faster builds and better cache use this also may lead to accidental stages
caches invalidations if the order of the extensions in the values.yml is changed as the stages
are created by groups of ten extensions, following the natural order as they appear in the values.yml

# Adding Extensions

To add a new extension to the Taqasta image:

1. Open `values.yml` in the root directory
2. Add a new entry under the `extensions` section following YAML schema format (`values.schema.json`)
3. Run `./validate.sh` to verify that the YAML file is valid against the schema
4. Run `./compile.sh` to verify that your addition has a valid syntax
5. Either run `./build` to build the updated image locally or push your change to remote branch to build using CI

See `values.schema.json` for fields definitions

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
