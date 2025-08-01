<?php

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

/**
 * Returns boolean value from environment variable
 * Must return the same result as isTrue function in run-apache.sh file
 * @param $value
 * @return bool
 */
function isEnvTrue( $name ): bool {
	$value = getenv( $name );
	switch ( $value ) {
		case "True":
		case "TRUE":
		case "true":
		case "1":
			return true;
	}
	return false;
}

const DOCKER_SKINS = [
	'CologneBlue',
	'MinervaNeue',
	'Modern',
	'MonoBook', # bundled
	'Refreshed',
	'Timeless', # bundled
	'Vector', # bundled
	'chameleon',
	'pivot',
];

const DOCKER_EXTENSIONS = [
	'SemanticMediaWiki', // keep it at the top to be enabled first, because some Semantic extension don't work in other case.
	'AJAXPoll',
	'AbuseFilter',
	'AddMessages',
	'AdminLinks',
	'AdvancedSearch',
	'AntiSpoof',
	'ApprovedRevs',
	'Arrays',
	'Auth_remoteuser',
	'BetaFeatures',
	'Bootstrap',
	'BootstrapComponents',
	'BreadCrumbs2',
	'Buggy',
	'Cargo',
	'CategoryTree', # bundled
	'ChangeAuthor',
	'CharInsert',
	'CheckUser',
	'CirrusSearch',
	'Cite', # bundled
	'CiteThisPage', # bundled
	'Citoid',
	'CodeEditor', # bundled
	'CodeMirror',
	'Collection',
	'CommentStreams',
	'CommonsMetadata',
	'ConfirmAccount',
	'ConfirmEdit', # bundled
	'ConfirmEdit/QuestyCaptcha', # bundled
	'ConfirmEdit/ReCaptchaNoCaptcha', # bundled
	'ContactPage',
	'ContributionScores',
	'CookieWarning',
	'Cloudflare',
	'DataTransfer',
	'DeleteBatch',
	'Description2',
	'Disambiguator',
	'DiscussionTools', # bundled
	'DismissableSiteNotice',
	'DisplayTitle',
	'DynamicPageList3',
	'Echo', # bundled
	'EditAccount',
	'Editcount',
	'Elastica',
	'EmailAuthorization',
	'EmbedVideo',
	'EventLogging',
	'EventStreamConfig',
	'ExternalData',
	'FlexDiagrams',
	'Flow',
	'GTag',
	'Gadgets', # bundled
	'GlobalNotice',
	'GoogleAnalyticsMetrics',
	'GoogleDocCreator',
	'GoogleDocTag',
	'GoogleLogin',
	'HTMLTags',
	'HeadScript',
	'HeaderFooter',
	'HeaderTabs',
	'IframePage',
	'ImageMap', # bundled
	'InputBox', # bundled
	'Interwiki', # bundled
	'JWTAuth',
	'LDAPAuthentication2',
	'LDAPAuthorization',
	'LDAPProvider',
	'LabeledSectionTransclusion',
	'Lazyload',
	'Lingo',
	'LinkSuggest',
	'LinkTarget',
	'Linter', # bundled
	'LiquidThreads',
	'LockAuthor',
	'Lockdown',
	'LoginNotify', # bundled
	'LookupUser',
	'Loops',
	'LuaCache',
	'MagicNoCache',
	'Maps',
	'MassMessage',
	'MassMessageEmail',
	'MassPasswordReset',
	'Math',
	'MediaUploader',
	'Mermaid',
	'MintyDocs',
	'MobileDetect',
	'MobileFrontend',
	'Mpdf',
	'MsUpload',
	'MultimediaViewer', # bundled
	'MyVariables',
	'NCBITaxonomyLookup',
	'NewUserMessage',
	'Nuke', # bundled
	'NumerAlpha',
	'OATHAuth', # bundled
	'OpenGraphMeta',
	'OpenIDConnect',
	'PDFEmbed',
	'PageExchange',
//	'PageForms',   must be enabled manually after enableSemantics()
	'PageImages', # bundled
	'PagePort',
	'PageSchemas',
	'ParserFunctions', # bundled
	'PdfHandler', # bundled
	'PluggableAuth',
	'Poem', # bundled
	'Popups',
	'PubmedParser',
	'RegularTooltips',
	'RemoteWiki',
	'ReplaceText', # bundled
	'RevisionSlider',
	'RottenLinks',
	'SandboxLink',
	'SaveSpinner',
	'Scopus',
	'Scribunto', # bundled
	'SecureLinkFixer', # bundled
	'SelectCategory',
	'SemanticCompoundQueries',
	'SemanticDependencyUpdater', //  must be enabled after SemanticMediaWiki
	'SemanticExtraSpecialProperties',
//	'SemanticMediaWiki', moved the top to be enabled first, because some Semantic extension don't work in other case.
	'SemanticResultFormats',
	'SemanticScribunto',
	'SemanticWatchlist',
	'Sentry',
	'ShowMe',
	'SimpleBatchUpload',
	'SimpleChanges',
	'SimpleMathJax',
	'SimpleTooltip',
	'SimpleTippy',
	'SkinPerNamespace',
	'SkinPerPage',
	'Skinny',
	'SmiteSpam',
	'SpamBlacklist', # bundled
	'SubPageList',
	'Survey',
	'SyntaxHighlight_GeSHi', # bundled
	'Tabber',
	'TabberNeue',
	'Tabs',
	'TemplateData', # bundled
	'TemplateStyles',
	'TemplateWizard',
	'TextExtracts', # bundled
	'Thanks', # bundled
	'TinyMCE',
	'TitleBlacklist', # bundled
	'TitleIcon',
	'TwitterTag',
	'UniversalLanguageSelector',
	'UploadWizard',
	'UploadWizardExtraButtons',
	'UrlGetParameters',
	'UserFunctions',
	'UserMerge',
	'UserPageViewTracker',
	'VEForAll',
	'Validator',
	'Variables',
	'VariablesLua',
	'VisualEditor', # bundled
	'VoteNY',
	'WatchAnalytics',
	'WSOAuth',
	'WSSlots',
	'WhoIsWatching',
	'Widgets',
	'WikiEditor', # bundled
	'WikiForum',
	'WikiSEO',
	'YouTube',
];

$DOCKER_MW_VOLUME = getenv( 'MW_VOLUME' );

########################### Core Settings ##########################

# The name of the site. This is the name of the site as displayed throughout the site.
$wgSitename  = getenv( 'MW_SITE_NAME' );

$wgMetaNamespace = "Project";

## The URL base path to the directory containing the wiki;
## defaults for all runtime URL paths are based off of this.
## For more information on customizing the URLs
## (like /w/index.php/Page_title to /wiki/Page_title) please see:
## https://www.mediawiki.org/wiki/Manual:Short_URL
$wgScriptPath = "/w";
$wgScriptExtension = ".php";

## The protocol and server name to use in fully-qualified URLs
if ( getenv( 'MW_SITE_SERVER' ) ) {
	$wgServer = getenv( 'MW_SITE_SERVER' );
}

## The URL path to static resources (images, scripts, etc.)
$wgResourceBasePath = $wgScriptPath;

## UPO means: this is also a user preference option

$wgEnableEmail = isEnvTrue( 'MW_ENABLE_EMAIL' );
$wgEnableUserEmail = isEnvTrue( 'MW_ENABLE_USER_EMAIL' );

$wgEmergencyContact = getenv( 'MW_EMERGENCY_CONTACT' );
$wgPasswordSender = getenv( 'MW_PASSWORD_SENDER' );

$wgEnotifUserTalk = false; # UPO
$wgEnotifWatchlist = false; # UPO
$wgEmailAuthentication = true;

## Database settings
$wgSQLiteDataDir = "$DOCKER_MW_VOLUME/sqlite";
$wgDBtype = getenv( 'MW_DB_TYPE' );
$wgDBserver = getenv( 'MW_DB_SERVER' );
$wgDBname = getenv( 'MW_DB_NAME' );
$wgDBuser = getenv( 'MW_DB_USER' );
$wgDBpassword = getenv( 'MW_DB_PASS' );
if ( !$wgDBpassword ) {
	if ( is_readable( '/run/secrets/db_password' ) ) {
		$wgDBpassword = rtrim( file_get_contents( '/run/secrets/db_password' ) );
	} elseif ( is_readable( '/run/secrets/db_root_password' ) ) {
		$wgDBpassword = rtrim( file_get_contents( '/run/secrets/db_root_password' ) );
	}
}

# MySQL specific settings
$wgDBprefix = "";

# MySQL table options to use during installation or update
$wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";

# Periodically send a pingback to https://www.mediawiki.org/ with basic data
# about this MediaWiki instance. The Wikimedia Foundation shares this data
# with MediaWiki developers to help guide future development efforts.
$wgPingback = false;

## If you use ImageMagick (or any other shell command) on a
## Linux server, this will need to be set to the name of an
## available UTF-8 locale
$wgShellLocale = "en_US.utf8";

## Set $wgCacheDirectory to a writable directory on the web server
## to make your wiki go slightly faster. The directory should not
## be publicly accessible from the web.
$wgCacheDirectory = isEnvTrue( 'MW_USE_CACHE_DIRECTORY' ) ? "$DOCKER_MW_VOLUME/l10n_cache" : false;

# Do not overwrite $wgSecretKey with empty string if MW_SECRET_KEY is not defined
$wgSecretKey = getenv( 'MW_SECRET_KEY' ) ?: $wgSecretKey;

# Changing this will log out all existing sessions.
$wgAuthenticationTokenVersion = "1";

## For attaching licensing metadata to pages, and displaying an
## appropriate copyright notice / icon. GNU Free Documentation
## License and Creative Commons licenses are supported so far.
$wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
$wgRightsUrl = "";
$wgRightsText = "";
$wgRightsIcon = "";

# Path to the GNU diff3 utility. Used for conflict resolution.
$wgDiff3 = "/usr/bin/diff3";

# see https://www.mediawiki.org/wiki/Manual:$wgCdnServersNoPurge
# Add docker networks as CDNs
$wgCdnServersNoPurge = [ '172.16.0.0/12', '192.168.0.0/16', '10.0.0.0/8' ];

if ( isEnvTrue( 'MW_SHOW_EXCEPTION_DETAILS' ) ) {
	$wgShowExceptionDetails = true;
}

# Site language code, should be one of the list in ./languages/Names.php
$wgLanguageCode = getenv( 'MW_SITE_LANG' ) ?: 'en';

# Allow images and other files to be uploaded through the wiki.
$wgEnableUploads  = isEnvTrue( 'MW_ENABLE_UPLOADS' );
$wgUseImageMagick = isEnvTrue( 'MW_USE_IMAGE_MAGIC' );

####################### Skin Settings #######################
# Default skin: you can change the default skin. Use the internal symbolic
# names, ie 'standard', 'nostalgia', 'cologneblue', 'monobook', 'vector':
$wgDefaultSkin = getenv( 'MW_DEFAULT_SKIN' );
$dockerLoadSkins = null;
$dockerLoadSkins = getenv( 'MW_LOAD_SKINS' );
if ( $dockerLoadSkins ) {
	$dockerLoadSkins = explode( ',', $dockerLoadSkins );
	$dockerLoadSkins = array_intersect( DOCKER_SKINS, $dockerLoadSkins );
	if ( $dockerLoadSkins ) {
		wfLoadSkins( $dockerLoadSkins );
	}
}
if ( !$dockerLoadSkins ) {
	wfLoadSkin( 'Vector' );
	$wgDefaultSkin = 'Vector';
} else{
	if ( !$wgDefaultSkin ) {
		$wgDefaultSkin = reset( $dockerLoadSkins );
	}
	$dockerLoadSkins = array_combine( $dockerLoadSkins, $dockerLoadSkins );
}

if ( isset( $dockerLoadSkins['chameleon'] ) ) {
	wfLoadExtension( 'Bootstrap' );
}

####################### Extension Settings #######################
// The variable will be an array [ 'extensionName' => 'extensionName, ... ]
// made by see array_combine( $dockerLoadExtensions, $dockerLoadExtensions ) below
$dockerLoadExtensions = getenv( 'MW_LOAD_EXTENSIONS' );
if ( $dockerLoadExtensions ) {
	$dockerLoadExtensions = explode( ',', $dockerLoadExtensions );
	$dockerLoadExtensions = array_intersect( DOCKER_EXTENSIONS, $dockerLoadExtensions );
	if ( $dockerLoadExtensions ) {
		$dockerLoadExtensions = array_combine( $dockerLoadExtensions, $dockerLoadExtensions );
		// Enable SemanticMediaWiki first, because some Semantic extension don't work in other case
		if ( isset( $dockerLoadExtensions['SemanticMediaWiki'] ) ) {
			wfLoadExtension( 'SemanticMediaWiki' );
		}
		foreach ( $dockerLoadExtensions as $extension ) {
			if ( $extension === 'SemanticMediaWiki' ) {
				// Already loaded above ^
				continue;
			}
			if ( file_exists( "$wgExtensionDirectory/$extension/extension.json" ) ) {
				wfLoadExtension( $extension );
			} else {
				require_once "$wgExtensionDirectory/$extension/$extension.php";
			}
		}
	}
}

# SyntaxHighlight_GeSHi
$wgPygmentizePath = '/usr/bin/pygmentize';

# SemanticMediaWiki
$smwgConfigFileDir = "$DOCKER_MW_VOLUME/extensions/SemanticMediaWiki/config";

# GoogleLogin, WIK-1434
$wgGLPublicSuffixArrayDir = "$DOCKER_MW_VOLUME/extensions/GoogleLogin/cache";

// Scribunto https://www.mediawiki.org/wiki/Extension:Scribunto
$wgScribuntoDefaultEngine = 'luasandbox';
$wgScribuntoEngineConf['luasandbox']['cpuLimit'] = '120';
$wgScribuntoUseGeSHi = boolval( $dockerLoadExtensions['SyntaxHighlight_GeSHi'] ?? false );
$wgScribuntoUseCodeEditor = boolval( $dockerLoadExtensions['CodeEditor'] ?? false );

# Interwiki
$wgGroupPermissions['sysop']['interwiki'] = true;

# InstantCommons allows wiki to use images from http://commons.wikimedia.org
$wgUseInstantCommons  = isEnvTrue( 'MW_USE_INSTANT_COMMONS' );

# Name used for the project namespace. The name of the meta namespace (also known as the project namespace), used for pages regarding the wiki itself.
#$wgMetaNamespace = 'Project';
#$wgMetaNamespaceTalk = 'Project_talk';

# The relative URL path to the logo.  Make sure you change this from the default,
# or else you'll overwrite your logo when you upgrade!
$wgLogo = "$wgScriptPath/logo.png";

##### Short URLs
## https://www.mediawiki.org/wiki/Manual:Short_URL
$wgArticlePath = '/wiki/$1';
## Also see mediawiki.conf

##### Jobs
# Number of jobs to perform per request. see https://www.mediawiki.org/wiki/Manual:$wgJobRunRate
$wgJobRunRate = 0;

# SVG Converters
$wgSVGConverter = 'rsvg';

##### Improve performance
# https://www.mediawiki.org/wiki/Manual:$wgMainCacheType
switch ( getenv( 'MW_MAIN_CACHE_TYPE' ) ) {
	case 'CACHE_ACCEL':
		# APC has several problems in latest versions of WediaWiki and extensions, for example:
		# https://www.mediawiki.org/wiki/Extension:Flow#.22Exception_Caught:_CAS_is_not_implemented_in_Xyz.22
		$wgMainCacheType = CACHE_ACCEL;
		$wgSessionCacheType = CACHE_DB; #This may cause problems when CACHE_ACCEL is used
		break;
	case 'CACHE_DB':
		$wgMainCacheType = CACHE_DB;
		break;
	case 'CACHE_ANYTHING':
		$wgMainCacheType = CACHE_ANYTHING;
		break;
	case 'CACHE_MEMCACHED':
		# Use Memcached, see https://www.mediawiki.org/wiki/Memcached
		$wgMainCacheType = CACHE_MEMCACHED;
		$wgParserCacheType = CACHE_MEMCACHED; # optional
		$wgMessageCacheType = CACHE_MEMCACHED; # optional
		$wgMemCachedServers = explode( ',', getenv( 'MW_MEMCACHED_SERVERS' ) );
		$wgSessionsInObjectCache = true; # optional
		$wgSessionCacheType = CACHE_MEMCACHED; # optional
		break;
	case 'CACHE_REDIS':
		$wgObjectCaches['redis'] = [
			'class' => 'RedisBagOStuff',
			'servers' => explode( ',', getenv( 'MW_REDIS_SERVERS' ) ),
		];
		$wgMainCacheType = 'redis';
		$wgSessionCacheType = CACHE_DB;
		break;
	default:
		$wgMainCacheType = CACHE_NONE;
}

# Use Varnish accelerator
$tmpProxy = getenv( 'MW_PROXY_SERVERS' );
if ( $tmpProxy ) {
	# https://www.mediawiki.org/wiki/Manual:Varnish_caching
	$wgUseCdn = true;
	$wgCdnServers = explode( ',', $tmpProxy );
	$wgUsePrivateIPs = true;
	# Use HTTP protocol for internal connections like PURGE request to Varnish
	if ( strncasecmp( $wgServer, 'https://', 8 ) === 0 ) {
		$wgInternalServer = 'http://' . substr( $wgServer, 8 ); // Replaces HTTPS with HTTP
	}
	// Re-warm up varnish cache after a purge.
	// Do this on LinksUpdate and not HTMLCacheUpdate because HTMLCacheUpdate
	// does 100 pages at a time very quickly which can overwhelm things.
	// WLDR-314.
	$wgHooks['LinksUpdateComplete'][] = function ( $linksUpdate ) {
		global $wgCdnServers;
		$url = $linksUpdate->getTitle()->getInternalURL();
		// Adapted from CdnCacheUpdate::naivePurge.
		foreach( $wgCdnServers as $server ) {
			$urlInfo = wfParseUrl( $url );
			$urlHost = strlen( $urlInfo['port'] ?? '' )
				? \Wikimedia\IPUtils::combineHostAndPort( $urlInfo['host'], (int)$urlInfo['port'] )
				: $urlInfo['host'];
			$baseReq = [
				'method' => 'GET',
				'url' => $url,
				'headers' => [
					'Host' => $urlHost,
					'Connection' => 'Keep-Alive',
					'Proxy-Connection' => 'Keep-Alive',
					'User-Agent' => 'MediaWiki/' . MW_VERSION . ' LinksUpdate',
				],
				'proxy' => $server
			];
			MediaWiki\MediaWikiServices::getInstance()->getHttpRequestFactory()
				->createMultiClient()->runMulti( [ $baseReq ] );
		}
	};
}

# AdvancedSearch
# Deep category searching requires SPARQL (like wikidata), should be disabled by default for non Wikimedia wikis
$wgAdvancedSearchDeepcatEnabled = false;

# Enable the "Did You Mean" feature, see WIK-1275
$wgCirrusSearchPhraseSuggestUseOpeningText = true;

######################### Custom Settings ##########################
$canastaLocalSettingsFilePath = getenv( 'MW_CONFIG_DIR' ) . '/LocalSettings.php';
$emulateLocalSettingsDoesNotExists = false;
if ( is_readable( "$IP/_settings/LocalSettings.php" ) ) {
	require_once "$IP/_settings/LocalSettings.php";
} elseif ( is_readable( "$IP/CustomSettings.php" ) ) {
	require_once "$IP/CustomSettings.php";
} elseif ( is_readable( $canastaLocalSettingsFilePath ) ) {
	require_once $canastaLocalSettingsFilePath;
} elseif ( getenv( 'MW_DB_TYPE' ) !== 'sqlite' && !getenv( 'MW_DB_SERVER' ) ) {
	// There are no LocalSettings.php files
	// and the database server is not defined (and it is not a sqlite database)
	$emulateLocalSettingsDoesNotExists = true;
}

if ( defined( 'MW_CONFIG_CALLBACK' ) ) {
	// Called from WebInstaller or similar entry point

	if ( $emulateLocalSettingsDoesNotExists	) {
		// Remove all variables, WebInstaller should decide that "$IP/LocalSettings.php" does not exist.
		$vars = array_keys( get_defined_vars() );
		foreach ( $vars as $v => $k ) {
			unset( $$k );
		}
		unset( $vars, $v, $k );
		return;
	}
}

if ( $emulateLocalSettingsDoesNotExists ) {
	// Emulate that "$IP/LocalSettings.php" does not exist

	// Set CANASTA_CONFIG_FILE for NoLocalSettings template work correctly in includes/CanastaNoLocalSettings.php
	define( "CANASTA_CONFIG_FILE", $canastaLocalSettingsFilePath );

	// Do the same what function wfWebStartNoLocalSettings() does
	require_once "$IP/includes/CanastaNoLocalSettings.php";
	die();
}

# Flow https://www.mediawiki.org/wiki/Extension:Flow
if ( isset( $dockerLoadExtensions['Flow'] ) ) {
	$flowNamespaces = getenv( 'MW_FLOW_NAMESPACES' );
	if ( $flowNamespaces ) {
		$wgFlowContentFormat = 'html';
		foreach ( explode( ',', $flowNamespaces ) as $ns ) {
			$wgNamespaceContentModels[ constant( $ns ) ] = 'flow-board';
		}
	}
}

########################### Search Type ############################
switch( getenv( 'MW_SEARCH_TYPE' ) ) {
	case 'CirrusSearch':
		# https://www.mediawiki.org/wiki/Extension:CirrusSearch
		wfLoadExtension( 'Elastica' );
		wfLoadExtension( 'CirrusSearch' );
		$wgCirrusSearchServers =  explode( ',', getenv( 'MW_CIRRUS_SEARCH_SERVERS' ) );
		if ( isset( $flowNamespaces ) ) {
			$wgFlowSearchServers = $wgCirrusSearchServers;
		}
		$wgSearchType = 'CirrusSearch';
		break;
}

########################### Sitemap ############################
if ( isEnvTrue('MW_ENABLE_SITEMAP_GENERATOR') ) {
	$wgHooks['BeforePageDisplay'][] = function ( $out, $skin ) {
		global $wgScriptPath;
		$subdir = getenv( 'MW_SITEMAP_SUBDIR' );
		# Adds slash to sitemap dir if it's not empty and has no starting slash
		if ( $subdir && $subdir[0] !== '/' ) {
			$subdir = '/' . $subdir;
		}
		$identifier = getenv( 'MW_SITEMAP_IDENTIFIER' );
		$out->addLink( [
			'rel' => 'sitemap',
			'type' => 'application/xml',
			'title' => 'Sitemap',
			'href' => "$wgScriptPath/sitemap$subdir/sitemap-index-$identifier.xml",
		] );
	};
}

# Sentry
$wgSentryDsn = getenv('MW_SENTRY_DSN');
if ( $wgSentryDsn ) {
	wfLoadExtension( 'Sentry' );
}

if ( isset( $_REQUEST['forceprofile'] ) ) {
	$wgProfiler['class'] = 'ProfilerXhprof';
	$wgProfiler['output'] = [ 'ProfilerOutputText' ];
	$wgProfiler['visible'] = false;
	$wgUseCdn = false; // make sure profile is not cached
}

if ( getenv( 'MW_AUTO_IMPORT' ) ) {
	wfLoadExtension( 'PagePort' );
}

if ( !empty( getenv( 'AWS_IMAGES_BUCKET' ) ) ) {
	// see https://github.com/edwardspec/mediawiki-aws-s3
	wfLoadExtension( 'AWS' );
	$wgAWSCredentials = [
		'key' => getenv( 'AWS_IMAGES_ACCESS' ),
		'secret' => getenv( 'AWS_IMAGES_SECRET' ),
		'token' => false
	];
	$wgAWSRegion = getenv( 'AWS_IMAGES_REGION' ); #eu-west-2
	$wgAWSBucketName = getenv( 'AWS_IMAGES_BUCKET' );
	if ( !empty( getenv( 'AWS_IMAGES_BUCKET_DOMAIN' ) ) ) {
		// $1.s3.eu-west-2.amazonaws.com, $1 is replaced with bucket name
		$wgAWSBucketDomain = getenv( 'AWS_IMAGES_BUCKET_DOMAIN' );
	}
	$wgFileBackends['s3']['privateWiki'] = false;
	// see https://github.com/edwardspec/mediawiki-aws-s3/blob/97c210475f82ed5bc86ea3cbf2726162ccbedbfe/s3/AmazonS3FileBackend.php#L97
	// if true, then all S3 objects are private and uploaded with appropriate ACLs.
	// for images to work in private mode, $wgUploadPath should point to img_auth.php
	if ( !empty( getenv( 'AWS_IMAGES_PRIVATE' ) ) ) {
		$wgFileBackends['s3']['privateWiki'] = true;
		// When private mode is enabled we MUST revoke read right from anonymous users
		// and MUST configure img_auth.php setting, see QLOUD-124
		// NOTE: any possible overrides of these settings in any of the subsequently
		// loaded configs (settings/*.php) must be REMOVED
		$wgGroupPermissions['*']['read'] = false;
		$wgUploadPath = "$wgScriptPath/img_auth.php";
	}
	if ( !empty( getenv( 'AWS_IMAGES_ENDPOINT' ) ) ) {
		$wgFileBackends['s3']['endpoint'] = getenv( 'AWS_IMAGES_ENDPOINT' );
	}
	if ( !empty( getenv( 'AWS_IMAGES_SUBDIR' ) ) ) {
		// i.e. '/subdir'
		$wgAWSBucketTopSubdirectory = getenv( 'AWS_IMAGES_SUBDIR' );
	}

	// some software (such as MinIO) doesn't use subdomains for buckets
	if ( !empty( getenv( 'AWS_IMAGES_USEPATH') ) ) {
		$wgFileBackends['s3']['use_path_style_endpoint'] = true;
	}
	// see https://github.com/edwardspec/mediawiki-aws-s3?tab=readme-ov-file#migrating-images
	// this configuration resembles native images storage structure to allow
	// for seamless migration of existing images to object storage
	$wgAWSRepoHashLevels = 2;
	$wgAWSRepoDeletedHashLevels = 3;
}

# Include all php files in config/settings directory
foreach ( glob( getenv( 'MW_CONFIG_DIR' ) . '/settings/*.php' ) as $filename ) {
	if ( is_readable( $filename ) ) {
		require_once $filename;
	} else {
		MWDebug::warning( 'Cannot read file: $filename' );
	}
}
