( function () {
	'use strict';

	const category = mw.config.get( 'wgCaptchaConsentCategory' );
	const VENDOR_HOSTS = [ 'recaptcha.net', 'www.recaptcha.net', 'hcaptcha.com', 'js.hcaptcha.com', 'challenges.cloudflare.com' ];

	function isVendorUrl( url ) {
		try {
			const u = new URL( url, location.href );
			return ( u.protocol === 'https:' || u.protocol === 'http:' ) && (
				VENDOR_HOSTS.indexOf( u.hostname ) !== -1 ||
				( u.hostname === 'www.google.com' && u.pathname.indexOf( '/recaptcha/' ) === 0 )
			);
		} catch ( e ) {
			return false;
		}
	}

	// Unknown state counts as denied. The cookie is read directly when CookieConsent has not loaded yet,
	// so the guard below does not depend on that module.
	function consentGiven() {
		if ( window.cookieConsent ) {
			return window.cookieConsent.isConsentGiven( category );
		}
		return mw.cookie.get( 'cookieconsent_consent_' + category ) === 'given';
	}

	function openPreferences( e ) {
		e.preventDefault();
		if ( window.cookieConsent ) {
			window.cookieConsent.openDetailedDialog();
		}
	}

	function buildNotice( msgKey ) {
		const $link = $( '<a>' ).attr( 'href', '#' )
			.text( mw.msg( 'captchaconsent-notice-link' ) ).on( 'click', openPreferences );
		const $notice = $( '<div>' ).addClass( 'cdx-message cdx-message--block cdx-message--warning mw-captchaconsent-notice' )
			.append( $( '<span>' ).addClass( 'cdx-message__icon' ) )
			.append( $( '<div>' ).addClass( 'cdx-message__content' )
				.append( document.createTextNode( mw.msg( msgKey, mw.config.get( 'wgCaptchaConsentCategoryLabel' ) ) + ' ' ), $link ) );
		return $notice;
	}

	// Form pages: show the reason above the CAPTCHA widget while the category is not granted.
	function showFormNotice() {
		if ( !mw.config.get( 'wgCaptchaConsentPageGated' ) || consentGiven() ) {
			return;
		}
		const $widget = $( '.g-recaptcha, .h-captcha, .cf-turnstile' ).first();
		if ( $widget.length && !$( '.mw-captchaconsent-notice' ).length ) {
			$widget.before( buildNotice( 'captchaconsent-notice' ) );
		}
	}

	// VisualEditor loads the vendor script with mw.loader.load. Hold it back until consent is given.
	// Granting consent reloads the page, so a held load is never resumed; show the reason instead.
	function guardLoader() {
		const original = mw.loader.load;
		mw.loader.load = function ( modules, type ) {
			if ( typeof modules === 'string' && isVendorUrl( modules ) && !consentGiven() ) {
				mw.notify( buildNotice( 'captchaconsent-ve-notice' ), { autoHide: false, type: 'warn' } );
				return;
			}
			return original.apply( this, arguments );
		};
	}

	// The guard goes in first: VisualEditor can call mw.loader.load before CookieConsent has loaded.
	guardLoader();
	mw.loader.using( 'ext.CookieConsent' ).then( () => {
		$( showFormNotice );
	}, () => {
		mw.log.warn( 'CaptchaConsent: ext.CookieConsent is not available, the CAPTCHA stays blocked' );
	} );
}() );
