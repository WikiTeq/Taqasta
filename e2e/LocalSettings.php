<?php

# MediaWiki settings during end-to-end tests with playwright

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

// Avoid beta welcome popup that might interfere with the save button
$wgVisualEditorShowBetaWelcome = false;
