<?php

namespace MediaWiki\Extension\CaptchaConsent;

/**
 * Pure string helpers that make third-party CAPTCHA markup wait for CookieConsent.
 */
class ScriptGate {

	/** ConfirmEdit head item keys that hold the vendor script. */
	public const HEAD_ITEM_KEYS = [ 'g-recaptchascript', 'h-captcha', 'cf-turnstile-script' ];

	private const VENDOR_HOSTS = [
		'recaptcha.net',
		'www.recaptcha.net',
		'hcaptcha.com',
		'js.hcaptcha.com',
		'challenges.cloudflare.com',
	];

	/**
	 * True if the URL points at a supported CAPTCHA vendor.
	 */
	public static function isVendorUrl( string $url ): bool {
		$parts = parse_url( html_entity_decode( $url ) );
		// '//host/..' (no scheme) and plain http are vendor URLs too, only the host decides
		if ( !is_array( $parts ) || !in_array( $parts['scheme'] ?? 'https', [ 'http', 'https' ], true ) || !isset( $parts['host'] ) ) {
			return false;
		}
		$host = strtolower( $parts['host'] );
		if ( in_array( $host, self::VENDOR_HOSTS, true ) ) {
			return true;
		}
		return $host === 'www.google.com' && strpos( $parts['path'] ?? '', '/recaptcha/' ) === 0;
	}

	/**
	 * Mark a vendor <script> so CookieConsent keeps it inactive until the category is granted.
	 *
	 * @return string|null The rewritten HTML, or null if the HTML is not a supported vendor script.
	 */
	public static function gateScript( string $html, string $category ): ?string {
		if ( !preg_match( '/^\s*<script\b([^>]*)>/i', $html, $m ) ) {
			return null;
		}
		if ( !preg_match( '/\bsrc\s*=\s*"([^"]*)"/i', $m[1], $src ) || !self::isVendorUrl( $src[1] ) ) {
			return null;
		}
		$attrs = preg_replace( '/\btype\s*=\s*"[^"]*"/i', '', $m[1] );
		$new = '<script type="text/plain" data-mw-cookieconsent="' . htmlspecialchars( $category ) . '"' . $attrs . '>';
		return preg_replace( '/^\s*<script\b[^>]*>/i', $new, $html, 1 );
	}

	/**
	 * Remove <noscript> blocks that embed a vendor iframe. A visitor without JavaScript cannot consent.
	 */
	public static function stripNoscript( string $html ): string {
		return preg_replace_callback(
			'#<noscript>.*?</noscript>#is',
			static function ( array $m ): string {
				if ( preg_match( '/<iframe\b[^>]*\bsrc\s*=\s*"([^"]*)"/i', $m[0], $src ) && self::isVendorUrl( $src[1] ) ) {
					return '';
				}
				return $m[0];
			},
			$html
		);
	}
}
