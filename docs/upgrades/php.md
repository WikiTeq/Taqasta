# PHP upgrades

Occasionally, we update the version of PHP that is used in our Taqasta image. PHP upgrades are performed when required for MediaWiki compatibility or image maintenance. Updates to PHP should generally be performed **separately** from updates to MediaWiki, to minimize the number of possible causes of errors.

PHP updates are also a good opportunity to update the base debian image used, but that is not a requirement.

## MediaWiki compatibility

Ensure that the new version of PHP is supported by the version of MediaWiki used. See [MediaWiki PHP compatibility](https://www.mediawiki.org/wiki/Special:MyLanguage/Compatibility#PHP) for the compatibility matrix.

## Extension compatibility

Before merging, confirm extensions listed in [values.yml](../../values.yml) build and pass tests on the new PHP version. If changes are needed to make extensions compatible, update the pinned commits or versions in [values.yml](../../values.yml) accordingly.

## Package source

Each version of debian ships with a specific version of PHP available by default. You can see the versions [on the debian wiki](https://wiki.debian.org/PHP). If the version of debian in the version of Taqasta with the new version of PHP ships that version of PHP by default, skip to the next step.

To be able to install versions of PHP not bundled with debian by default, use Ondřej Surý's packages. If not already available, follow [the instructions](https://codeberg.org/oerdnj/deb.sury.org/wiki/Frequently-Asked-Questions) for adding Ondřej's repository. The packages might already be available if the previous version of PHP used in Taqasta was sourced from that repository.

## Package versions

Update all system packages that are installed to switch the version from the old (e.g. PHP 8.1) to the new (e.g. PHP 8.3). Make sure that all of the PHP extensions that are installed have versions that are compatible with the new version of PHP.

You may also need to have the docker file include `update-alternatives` commands to ensure that the new version is used by default. Check the output of the version information for `php --version`, `phar version`, and `phar.phar version`:

<details>
<summary>Example</summary>

```console
root@965cb0e16c87:/var/www/mediawiki/w# php --version
PHP 8.3.28 (cli) (built: Nov 20 2025 11:50:57) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.28, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.28, Copyright (c), by Zend Technologies

root@965cb0e16c87:/var/www/mediawiki/w# phar version
PHP Version:               8.3.28
phar.phar version:         $Id: 17c5c6051fafe1e675ff9f6b7fc98afd448b8521 $
Phar EXT version:          8.3.28
Phar API version:          1.1.1
Phar-based phar archives:  enabled
Tar-based phar archives:   enabled
ZIP-based phar archives:   enabled
gzip compression:          enabled
bzip2 compression:         disabled
supported signatures:      MD5, SHA-1, SHA-256, SHA-512, OpenSSL, OpenSSL_SHA256, OpenSSL_SHA512

root@965cb0e16c87:/var/www/mediawiki/w# phar.phar version
PHP Version:               8.3.28
phar.phar version:         $Id: 17c5c6051fafe1e675ff9f6b7fc98afd448b8521 $
Phar EXT version:          8.3.28
Phar API version:          1.1.1
Phar-based phar archives:  enabled
Tar-based phar archives:   enabled
ZIP-based phar archives:   enabled
gzip compression:          enabled
bzip2 compression:         disabled
supported signatures:      MD5, SHA-1, SHA-256, SHA-512, OpenSSL, OpenSSL_SHA256, OpenSSL_SHA512
```

</details>

## PHP configuration

Identify all places where PHP configuration is manipulated in the image, and ensure that the file names reflect the new version of PHP.

## Resources

You may find it useful to consult the patches for the previous Taqasta PHP updates:

- [PHP 7.4 → 8.1](https://github.com/WikiTeq/Taqasta/commit/cb4631f55fe407eff0d5266092abde1fd3c91620)
- [PHP 8.1 → 8.3](https://github.com/WikiTeq/Taqasta/commit/bce2fa4bfc9daf2c1d3aca73f382745c5c4cd1ee)
