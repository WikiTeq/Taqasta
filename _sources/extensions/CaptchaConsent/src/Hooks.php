<?php

namespace MediaWiki\Extension\CaptchaConsent;

use MediaWiki\Hook\BeforePageDisplayHook;
use MediaWiki\Output\OutputPage;
use MediaWiki\Registration\ExtensionRegistry;
use Psr\Log\LoggerInterface;

class Hooks implements BeforePageDisplayHook {

	/**
	 * The category name, or '' when the gate is off.
	 * A configured category always gates. If CookieConsent is missing or does not know the category,
	 * the scripts stay inactive (fail closed) and a warning is logged, because a typo must not
	 * switch the protection off without notice.
	 */
	private function getCategory( OutputPage $out ): string {
		$category = (string)$out->getConfig()->get( 'CaptchaConsentCategory' );
		if ( $category === '' ) {
			return '';
		}
		$registry = ExtensionRegistry::getInstance();
		if ( !$registry->isLoaded( 'ConfirmEdit' ) ) {
			return '';
		}
		if ( !$registry->isLoaded( 'CookieConsent' ) ||
			!isset( $out->getConfig()->get( 'CookieConsentCategories' )[$category] )
		) {
			$this->logger()->warning(
				'CaptchaConsentCategory "{category}" is not available in CookieConsent, CAPTCHA scripts stay blocked',
				[ 'category' => $category ]
			);
		}
		return $category;
	}

	private function logger(): LoggerInterface {
		return \MediaWiki\Logger\LoggerFactory::getInstance( 'CaptchaConsent' );
	}

	/** @inheritDoc */
	public function onBeforePageDisplay( $out, $skin ): void {
		$category = $this->getCategory( $out );
		if ( $category === '' ) {
			return;
		}
		$gated = false;
		// ConfirmEdit adds the script under a fixed key on form pages, and under a numeric key in the
		// classic edit form (SimpleCaptcha::addFormInformationToOutput), so check every head item.
		foreach ( $out->getHeadItemsArray() as $key => $html ) {
			if ( !is_string( $html ) || stripos( $html, '<script' ) === false ) {
				continue;
			}
			$new = ScriptGate::gateScript( $html, $category );
			if ( $new === null ) {
				if ( in_array( $key, ScriptGate::HEAD_ITEM_KEYS, true ) ) {
					$this->logger()->warning( 'CAPTCHA head item "{key}" has an unsupported script URL, not gated', [
						'key' => $key,
					] );
				}
				continue;
			}
			$out->addHeadItem( (string)$key, $new );
			$gated = true;
		}
		// Forms are added with addHTML(), which OutputPageBeforeHTML does not see, so clean the finished body.
		$body = $out->getHTML();
		if ( stripos( $body, '<noscript' ) !== false ) {
			$clean = ScriptGate::stripNoscript( $body );
			if ( $clean !== $body ) {
				$out->clearHTML();
				$out->addHTML( $clean );
			}
		}
		// The module also guards the VisualEditor, which loads the vendor script from JavaScript.
		$labelMsg = ( $out->getConfig()->get( 'CookieConsentCategories' )[$category] ?? [] )['namemsg'] ?? null;
		$out->addJsConfigVars( [
			'wgCaptchaConsentCategory' => $category,
			'wgCaptchaConsentPageGated' => $gated,
			'wgCaptchaConsentCategoryLabel' => $labelMsg ? $out->msg( $labelMsg )->text() : $category,
		] );
		$out->addModules( 'ext.captchaConsent' );
	}
}
