# Minor MediaWiki updates

Every few months, a new minor release of MediaWiki is made with bug fixes and security patches. E.g. `1.43.5`. When these new releases come out, we need to update Taqasta. For major LTS updates, see [mediawiki-major.md](mediawiki-major.md).

We do not expect much trouble with minor updates, since extensions continue on their respective branches.

Open a pull request in [WikiTeq/Taqasta](https://github.com/WikiTeq/Taqasta) updating the base version of MediaWiki in [templates/base.Dockerfile](../../templates/base.Dockerfile):

```diff
 ENV MW_VERSION=REL1_43 \
-	MW_CORE_VERSION=1.43.9 \
+	MW_CORE_VERSION=1.43.10 \
 	WWW_ROOT=/var/www/mediawiki \
```

You may also need to update the `psy/psysh` composer constraint to match the constraint in the new version of MediaWiki. Failure to do so may lead to the image failing to build, either immediately or after additional versions of `psy/psysh` are released. Locate the constraint to use in the `require-dev` section of core's `composer.json`, and update Taqasta's [values.yml](../../values.yml) accordingly if the values are different.

Once built, you can test the image locally using [docker-compose.sample.yml](../../docker-compose.sample.yml) as a reference. After the PR merges, update production deployments to the new image tag (see [deployment.md](../deployment.md#image-tags)).
