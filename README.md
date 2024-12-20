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

## Environment Variable Management with `*_FILE`

Taqasta simplifies the configuration of environment variables by supporting `*_FILE`
variables, which allow you to specify paths to files (e.g., Docker secrets) that contain
the variable’s value. If the corresponding environment variable is not already defined
and the file exists, its content is automatically read and assigned to the environment variable.
For example, if `MW_DB_PASS_FILE` is specified and points to a valid file,
the variable `MW_DB_PASS` will be automatically populated with the file's content.

### Predefined Variables

Several environment variables are predefined in Taqasta, allowing you to easily use
Docker secret files without needing to manually define `*_FILE` variables.
Below is the list of predefined `*_FILE` environment variables and their
corresponding default paths:

```
MW_DB_PASS_FILE="/run/secrets/db_password /run/secrets/db_root_password"
MW_DB_INSTALLDB_PASS_FILE=/run/secrets/db_root_password
MW_ADMIN_USER_FILE=/run/secrets/mw_admin_user
MW_ADMIN_PASS_FILE=/run/secrets/mw_admin_password
MW_SENTRY_DSN_FILE=/run/secrets/mw_sentry_dns
```

Note that the WikiTeq team, which maintains Taqasta, also maintains a dedicated
branch of Canasta that is much more closely aligned with Canasta but includes
various extensions and other tweaks that the WikiTeq team uses.

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
