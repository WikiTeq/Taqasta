<?php
# This file pretends to be a /robots.txt file (via Apache rewrite, see configs/mediawiki.conf)
# Sitemap URL pattern is ${SITE_SERVER}${SCRIPT_PATH}/sitemap${SITEMAP_DIR}/sitemap-index-${MW_SITEMAP_IDENTIFIER}.xml

ini_set( 'display_errors', 0 );
error_reporting( 0 );

header( 'Content-Type: text/plain' );

$robotsDisallowed = getenv( 'ROBOTS_DISALLOWED' );
if ( !empty( $robotsDisallowed ) && in_array( strtolower($robotsDisallowed), [ 'true', '1' ] ) ) {
	die( "User-agent: *\nDisallow: /\n" );
}

$enableSitemapEnv = getenv( 'MW_ENABLE_SITEMAP_GENERATOR');
// match the value check to the isTrue function at _sources/scripts/functions.sh
if ( !empty( $enableSitemapEnv ) && in_array( $enableSitemapEnv, [ 'true', 'True', 'TRUE', '1' ] ) ) {
	$server = getenv( 'MW_SITE_SERVER' );
	$script = shell_exec( 'php /getMediawikiSettings.php --variable="wgScriptPath" --format="string"' );
	$subdir = getenv( 'MW_SITEMAP_SUBDIR' );
	$identifier = getenv( 'MW_SITEMAP_IDENTIFIER' );

	$siteMapUrl = "$server$script/sitemap$subdir/sitemap-index-$identifier.xml";

	echo "Sitemap: $siteMapUrl";
}

readfile( 'robots.txt' );
