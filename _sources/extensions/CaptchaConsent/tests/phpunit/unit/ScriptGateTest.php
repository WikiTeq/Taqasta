<?php

namespace MediaWiki\Extension\CaptchaConsent\Tests;

use MediaWiki\Extension\CaptchaConsent\ScriptGate;
use MediaWikiUnitTestCase;

/**
 * @covers \MediaWiki\Extension\CaptchaConsent\ScriptGate
 */
class ScriptGateTest extends MediaWikiUnitTestCase {

	public static function provideVendorScripts(): array {
		return [
			'recaptcha' => [ '<script src="https://www.recaptcha.net/recaptcha/api.js?hl=en" async defer></script>' ],
			'hcaptcha' => [ '<script src="https://hcaptcha.com/1/api.js" async defer></script>' ],
			'hcaptcha js host' => [ '<script src="https://js.hcaptcha.com/1/api.js" async defer></script>' ],
			'turnstile with newline' => [
				"<script src=\"https://challenges.cloudflare.com/turnstile/v0/api.js?language=en\" async defer>\n\t\t\t</script>"
			],
			'plain http' => [ '<script src="http://hcaptcha.com/1/api.js" async defer></script>' ],
			'protocol relative' => [ '<script src="//hcaptcha.com/1/api.js" async defer></script>' ],
			'google recaptcha path' => [ '<script src="https://www.google.com/recaptcha/api.js" async></script>' ],
		];
	}

	/** @dataProvider provideVendorScripts */
	public function testGateScript( string $html ) {
		$out = ScriptGate::gateScript( $html, 'captcha' );
		$this->assertStringStartsWith( '<script type="text/plain" data-mw-cookieconsent="captcha"', $out );
		$this->assertStringContainsString( 'src="', $out );
		$this->assertStringContainsString( 'async', $out );
		$this->assertSame( 1, substr_count( $out, 'type=' ) );
	}

	public static function provideOtherScripts(): array {
		return [
			'other host' => [ '<script src="https://example.org/api.js"></script>' ],
			'lookalike host' => [ '<script src="https://evil-hcaptcha.com/1/api.js"></script>' ],
			'vendor as subdomain of attacker' => [ '<script src="https://hcaptcha.com.example.org/1/api.js"></script>' ],
			'google non-recaptcha' => [ '<script src="https://www.google.com/maps/api.js"></script>' ],
			'inline script' => [ '<script>var a = 1;</script>' ],
			'not a script' => [ '<div class="h-captcha"></div>' ],
		];
	}

	/** @dataProvider provideOtherScripts */
	public function testGateScriptIgnoresOthers( string $html ) {
		$this->assertNull( ScriptGate::gateScript( $html, 'captcha' ) );
	}

	public function testGateScriptEscapesCategory() {
		$out = ScriptGate::gateScript( '<script src="https://hcaptcha.com/1/api.js"></script>', 'a"b' );
		$this->assertStringContainsString( 'data-mw-cookieconsent="a&quot;b"', $out );
	}

	public function testStripNoscriptRemovesVendorFallback() {
		$html = '<div class="g-recaptcha"></div><noscript><iframe src="https://www.recaptcha.net/recaptcha/api/fallback?k=x"></iframe>'
			. '<textarea id="g-recaptcha-response"></textarea></noscript><p>after</p>';
		$this->assertSame( '<div class="g-recaptcha"></div><p>after</p>', ScriptGate::stripNoscript( $html ) );
	}

	public function testStripNoscriptKeepsUnrelatedBlocks() {
		$html = '<noscript><img src="https://example.org/pixel.gif"></noscript>';
		$this->assertSame( $html, ScriptGate::stripNoscript( $html ) );
	}
}
