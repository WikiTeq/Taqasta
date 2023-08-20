#!/bin/bash

# Setup
apt update -qq > /dev/null
apt install -y php7.4-sqlite3 sqlite3 sqlitebrowser nodejs npm -qq > /dev/null
composer -n --quiet update

php maintenance/install.php \
  --scriptpath / \
  --dbtype mysql \
  --dbuser root \
  --dbname mediawiki \
  --dbpass mediawiki \
  --pass AdminPassword \
  --dbport 3306 \
  --dbserver host.docker.internal \
  --installdbuser root \
  --installdbpass mediawiki \
  WikiName \
  AdminUser

#  > /dev/null

echo 'error_reporting(0);' >> LocalSettings.php
echo 'wfLoadExtension("Bootstrap");' >> LocalSettings.php
echo '$wgShowExceptionDetails = false;' >> LocalSettings.php
echo '$wgShowDBErrorBacktrace = false;' >> LocalSettings.php
echo '$wgDevelopmentWarnings = false;' >> LocalSettings.php

php maintenance/update.php --quick > /dev/null

# Lint
# composer run-script test

# PHPUnit
#php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite integration
#php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite documentation
#php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite tests
#php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite maintenance_suite
#php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite parsertests
#php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error --testsuite languages

#cat tests/phpunit/includes/HooksTest.php | grep -A 5 testCallHook_Deprecated
#cat tests/phpunit/includes/HooksTest.php | grep -A 5 "function someStatic"
#php tests/phpunit/phpunit.php tests/phpunit/includes/HooksTest.php

# Qunit
