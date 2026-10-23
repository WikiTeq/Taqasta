# CAPTCHA and cookie consent

The `CaptchaConsent` extension keeps third-party CAPTCHA scripts (reCAPTCHA, hCaptcha, Cloudflare Turnstile) inactive until the visitor accepts a CookieConsent category. Without it, ConfirmEdit loads the vendor script before the visitor chooses, and the vendor receives the visitor's data.

The extension lives in this repository at [_sources/extensions/CaptchaConsent](../_sources/extensions/CaptchaConsent) and is copied into the image by [templates/final.Dockerfile](../templates/final.Dockerfile). It is not listed in [values.yml](../values.yml), because that file only holds extensions that are cloned or installed with Composer.

## Enabling it on a wiki

Add the following to the wiki's `LocalSettings.php`. ConfirmEdit and CookieConsent must also be loaded.

```php
wfLoadExtension( 'CaptchaConsent' );
$wgCookieConsentCategories['captcha'] = [
	'namemsg' => 'cookieconsent-category-name-marketing', // or a message of your own
	'descriptionmsg' => 'cookieconsent-category-desc-marketing',
	'selected' => false,
	'disabled' => false,
];
$wgCaptchaConsentCategory = 'captcha';
```

`$wgCaptchaConsentCategory` is empty by default. An empty value turns the gate off and the page HTML stays the same as without the extension. If the category is set but CookieConsent is missing or does not define it (for example a typo), the gate fails closed: the CAPTCHA scripts stay inactive, the visitor cannot accept the category, and a warning is written to the `CaptchaConsent` log channel. Fix the setting to restore the CAPTCHA.

## What the visitor sees

Before consent, the vendor script does not load, the CAPTCHA widget does not render, and a notice above the widget names the category and links to the cookie preferences dialog. After the visitor accepts the category, the page reloads and the CAPTCHA works. After the visitor withdraws consent, the script no longer loads on the next page view.

A visitor who rejects the category cannot complete an action that needs a CAPTCHA, for example account creation. Actions that do not trigger a CAPTCHA are not affected. Accepting the category reloads the page, so text typed into the form is lost.

## How it works

On every page the extension changes the ConfirmEdit head item for the vendor script to `type="text/plain" data-mw-cookieconsent="<category>"`, which CookieConsent activates after consent. The change does not depend on the visitor, so cached pages stay valid. The extension also removes the reCAPTCHA `<noscript>` iframe, because a visitor without JavaScript cannot consent. In the VisualEditor, a small module holds back the vendor script and shows the notice in the save dialog until consent is given.

Only script URLs on known vendor hosts are changed. An unknown URL is left alone and a warning is written to the `CaptchaConsent` log channel.

## Rollback

Set `$wgCaptchaConsentCategory = '';` or remove `wfLoadExtension( 'CaptchaConsent' )`.

## After a MediaWiki or ConfirmEdit upgrade

Check that the vendor script URLs in the ConfirmEdit `HTML*Field.php` files still match the hosts in `ScriptGate.php`, and that the three head item keys have not changed. Check the `CaptchaConsent` log for "unsupported script URL" warnings.

## Tests

Unit tests are in `_sources/extensions/CaptchaConsent/tests/phpunit`. The browser test is `e2e/tests/006-captcha-consent.spec.ts`. It intercepts the vendor URL, so no request reaches the vendor.
