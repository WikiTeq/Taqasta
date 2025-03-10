<?php

# MediaWiki settings during end-to-end tests with playwright

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

// General settings that could be done via the environment but aren't because
// normally wikis put their settings in PHP
$wgCacheDirectory = false;
$wgSecretKey = 'jf843y8973098waujda9odu89seyf9s4fy98sof49gyh47e3w9yhf9os';
$wgEnableUploads = true;

wfLoadSkin( 'Vector' );
$wgDefaultSkin = 'vector';

wfLoadExtension( 'ParserFunctions' );

// Needed for testing LuaSandbox on Special:Version
wfLoadExtension( 'Scribunto' );

// Needed for testing that VisualEditor is installed
wfLoadExtension( 'VisualEditor' );

// Avoid beta welcome popup that might interfere with the save button
$wgVisualEditorShowBetaWelcome = false;

// Allow testing uploads without needing to log in
$wgGroupPermissions['*']['upload'] = true;
