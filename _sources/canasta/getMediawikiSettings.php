<?php

use MediaWiki\MediaWikiServices;
use MediaWiki\Settings\SettingsBuilder;

$mwHome = getenv( 'MW_HOME' );

if ( !defined( 'MW_CONFIG_FILE' ) && !file_exists( "$mwHome/LocalSettings.php" ) ) {
	define( 'MW_CONFIG_FILE', "$mwHome/DockerSettings.php" );
}

require_once "$mwHome/maintenance/Maintenance.php";

class GetMediawikiSettings extends Maintenance {

	public function __construct() {
		parent::__construct();
		$this->addOption(
			'variable',
			'Returns the value of a variable',
			false,
			true
		);
		$this->addOption(
			'version',
			'Returns the version of the installed extension or MediaWiki',
			false,
			true
		);
		$this->addOption(
			'versions',
			'Returns the versions of all installed extensions and MediaWiki',
			false,
			false
		);
		$this->addOption(
			'isSMWValid',
			'Returns "true" if SMW does not require to run the update.php maintenance script',
		);
		$this->addOption(
			'SMWUpgradeKey',
			'Returns the SMW upgrading key (this key verifies that a correct upgrade)',
		);
		$this->addOption(
			'SWMIncompleteSetupTasks',
			'Returns list of the SMW maintenance tasks that should be run',
		);
		$this->addOption(
			'format',
			'Sets the output format. By default, it returns the value as a string or JSON if the returned value is an array. Possible values: string, json, md5, first (the first valuse from the array), and imploded array with separator: semicolon, space',
			false,
			true
		);
	}

	public function execute() {
		$return = null;
		if ( $this->hasOption( 'variable' ) ) {
			$variableName = $this->getOption( 'variable' );
			$config = MediaWikiServices::getInstance()->getMainConfig();
			if ( $config->has( $variableName ) ) {
				$return = $config->get( $variableName );
			} else { // the last chance to fetch a value from global variable
				$return = $GLOBALS[$variableName] ?? '';
			}
		} elseif ( $this->hasOption( 'versions' ) || $this->hasOption( 'version' ) ) {
			$return = [
				'MediaWiki' => SpecialVersion::getVersion( 'nodb' ),
			];
			$extThings = self::getExtensionsThings();
			foreach ( $extThings as $name => $extension ) {
				$return[$name] = $extension['version'] ?? '';
				// Try to add git version
				if ( isset( $extension['path'] ) ) {
					$extensionPath = dirname( $extension['path'] );
					$gitInfo = new GitInfo( $extensionPath );
					$gitVersion = substr( $gitInfo->getHeadSHA1() ?: '', 0, 7 );
					$return[$name] .= " ($gitVersion)";
				}
			}
			$versionName = $this->hasOption( 'version' ) ? $this->getOption( 'version' ) : null;
			if ( $versionName ) {
				$return = $return[$versionName] ?? null;
				if ( $return === '' ) {
					$return = '-';
				}
			}
		} elseif ( $this->hasOption( 'isSMWValid' ) ) {
			$extThings = self::getExtensionsThings();
			if ( isset( $extThings['SemanticMediaWiki'] ) ) {
				$this->output( SMW\Setup::isValid() ? 'true' : 'false' );
			} else {
				$this->output( 'SMW not installed' );
			}
			return;
		} elseif ( $this->hasOption( 'SMWUpgradeKey' ) ) {
			$extThings = self::getExtensionsThings();
			if ( isset( $extThings['SemanticMediaWiki'] ) ) {
				SemanticMediaWiki::onExtensionFunction();
				$smwId = SMW\Site::id();
				$return = $GLOBALS['smw.json'][$smwId]['upgrade_key'] ?? '';
			}
		} elseif ( $this->hasOption( 'SWMIncompleteSetupTasks' ) ) {
			$extThings = self::getExtensionsThings();
			if ( isset( $extThings['SemanticMediaWiki'] ) ) {
				SemanticMediaWiki::onExtensionFunction();
				$SMWSetupFile = new SMW\SetupFile();
				$SMWIncompleteTasks = $SMWSetupFile->findIncompleteTasks();
				$return = $SMWIncompleteTasks;
			}
		}

		$format = $this->getOption( 'format', 'string' );
		if ( $format === 'md5' ) {
			if ( is_array( $return ) ) {
				$return = FormatJson::encode( $return );
			}
			$this->output( md5( $return ) );
		} elseif ( $format === 'first' ) {
			if ( is_array( $return ) ) {
				if ( $return ) {
					$return = array_values( $return )[0];
				} else {
					$return = '';
				}
			}
			$this->output( $return );
		} elseif ( $format === 'semicolon' ) {
			if ( is_array( $return ) ) {
				$return = implode( ';', $return );
			}
			$this->output( $return );
		} elseif ( $format === 'space' ) {
			if ( is_array( $return ) ) {
				$return = implode( ' ', $return );
			}
			$this->output( $return );
		} elseif ( is_array( $return ) || strcasecmp( $format, 'json' ) === 0 ) {
			// return json format by default for an array
			$this->output( FormatJson::encode( $return ) );
		} else { // string
			$this->output( $return );
		}
	}

	public function getDbType() {
		return Maintenance::DB_NONE;
	}

	/**
	 * Remove values from the SetupAfterCache hooks at last-minute setup because
	 * some extensions makes requests to the database using the SetupAfterCache hook
	 * (for example they can check user and etc..)
	 * but this script can be used for getting parameters when database is not initialized yet
	 *
	 * @param SettingsBuilder|null $settingsBuilder
	 */
	public function finalSetup( SettingsBuilder $settingsBuilder = null ) {
		parent::finalSetup( $settingsBuilder );

		global $wgShowExceptionDetails, $wgHooks;

		$wgShowExceptionDetails = true;
		$wgHooks['SetupAfterCache'] = [ function () {
			global $wgExtensionFunctions;
			$wgExtensionFunctions = [];
			return false;
		} ];
	}

	private static function getExtensionsThings() {
		$extensionRegistry = ExtensionRegistry::getInstance();
		return $extensionRegistry->getAllThings();
	}
}

$maintClass = GetMediawikiSettings::class;
require RUN_MAINTENANCE_IF_MAIN;
