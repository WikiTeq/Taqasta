#!/bin/bash

apt update
apt install -y php7.4-sqlite3 sqlite3 sqlitebrowser
composer update
php maintenance/install.php --dbtype sqlite --dbuser root --dbname mw --dbpath $(pwd) --pass AdminPassword WikiName AdminUser
echo 'error_reporting(0);' >> LocalSettings.php
echo 'wfLoadExtension("Bootstrap");' >> LocalSettings.php
echo '$wgShowExceptionDetails = false;' >> LocalSettings.php
echo '$wgShowDBErrorBacktrace = false;' >> LocalSettings.php
echo '$wgDevelopmentWarnings = false;' >> LocalSettings.php
php maintenance/update.php --quick
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite integration
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite documentation
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite tests
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite maintenance_suite
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite parsertests
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite languages
