import {test, expect} from '@playwright/test';

// The wiki only loads CookieConsent, ConfirmEdit (hCaptcha) and CaptchaConsent for browsers that send the
// e2e_captcha_consent cookie, see e2e/LocalSettings.php. Special:CreateAccount always shows a CAPTCHA there.
// Vendor requests are intercepted, nothing reaches hcaptcha.com.
const VENDOR_URL = 'https://hcaptcha.com/1/api.js';

test.describe.configure({ mode: 'serial' });

async function useSetup(context, baseURL, value: string) {
    await context.addCookies([{name: 'e2e_captcha_consent', value, url: baseURL!}]);
}

test.beforeEach(async ({context, baseURL}) => {
    await useSetup(context, baseURL, '1');
});

async function trackVendor(page) {
    const requests: string[] = [];
    await page.route(VENDOR_URL + '**', async route => {
        requests.push(route.request().url());
        await route.fulfill({
            contentType: 'text/javascript',
            body: "document.querySelector('.h-captcha').setAttribute('data-rendered', '1');"
        });
    });
    return requests;
}

test('CAPTCHA script stays inactive and the notice shows before consent', async ({page}) => {
    const requests = await trackVendor(page);
    await page.goto('/wiki/Special:CreateAccount');

    const script = page.locator('script[data-mw-cookieconsent="captcha"]');
    await expect(script).toHaveAttribute('type', 'text/plain');
    await expect(page.locator('.mw-captchaconsent-notice')).toBeVisible();
    await expect(page.locator('.mw-captchaconsent-notice a')).toBeVisible();
    expect(requests).toHaveLength(0);
});

test('the notice link opens the cookie preferences dialog', async ({page}) => {
    await trackVendor(page);
    // Dismissed dialog without consent, so the notice link is not covered by the first-visit dialog
    await page.goto('/wiki/Special:CreateAccount');
    await page.evaluate(() => mw.cookie.set('cookieconsent_dialog_dismissed', 'yes'));
    await page.reload();
    await page.locator('.mw-captchaconsent-notice a').click();
    await expect(page.getByText('Advertising cookies').first()).toBeVisible();
});

test('CAPTCHA script loads after the category is accepted and stops after withdrawal', async ({page}) => {
    const requests = await trackVendor(page);
    // Store consent like the dialog does. mw.cookie adds the wiki's cookie prefix.
    await page.goto('/wiki/Special:CreateAccount');
    await page.evaluate(() => {
        mw.cookie.set('cookieconsent_dialog_dismissed', 'yes');
        mw.cookie.set('cookieconsent_consent_captcha', 'given');
    });
    await page.reload();
    await expect(page.locator('.h-captcha')).toHaveAttribute('data-rendered', '1');
    await expect(page.locator('.mw-captchaconsent-notice')).toHaveCount(0);
    expect(requests.length).toBeGreaterThan(0);

    // Withdraw
    await page.evaluate(() => mw.cookie.set('cookieconsent_consent_captcha', null));
    requests.length = 0;
    await page.reload();
    await expect(page.locator('.mw-captchaconsent-notice')).toBeVisible();
    expect(requests).toHaveLength(0);
});

test('classic edit form CAPTCHA script is gated too', async ({page}) => {
    const requests = await trackVendor(page);
    await page.goto('/index.php?title=CaptchaConsentTest&action=edit');
    await expect(page.locator('script[data-mw-cookieconsent="captcha"]')).toHaveAttribute('type', 'text/plain');
    await expect(page.locator('.mw-captchaconsent-notice')).toBeVisible();
    expect(requests).toHaveLength(0);
});

test('reCAPTCHA noscript fallback iframe is removed from the page', async ({page, context, baseURL}) => {
    await useSetup(context, baseURL, 'recaptcha');
    // Raw response, a browser would hide <noscript> content when JavaScript is on
    for (const path of ['/wiki/Special:CreateAccount', '/index.php?title=CaptchaConsentTest&action=edit']) {
        const html = await (await context.request.get(path)).text();
        expect(html).toContain('g-recaptcha');
        expect(html).toContain('data-mw-cookieconsent="captcha"');
        expect(html).not.toContain('recaptcha/api/fallback');
    }
});

test('with the gate switched off the vendor script is untouched and loads', async ({page, context, baseURL}) => {
    // ConfirmEdit and CaptchaConsent are loaded, but the category is empty
    await useSetup(context, baseURL, 'ungated');
    const requests = await trackVendor(page);
    await page.goto('/wiki/Special:CreateAccount');
    await expect(page.locator('script[data-mw-cookieconsent]')).toHaveCount(0);
    await expect(page.locator('.mw-captchaconsent-notice')).toHaveCount(0);
    await expect(page.locator('.h-captcha')).toHaveAttribute('data-rendered', '1');
    expect(requests.length).toBeGreaterThan(0);
});

test('an unknown category fails closed: the script stays inactive', async ({page, context, baseURL}) => {
    await useSetup(context, baseURL, 'typo');
    const requests = await trackVendor(page);
    await page.goto('/wiki/Special:CreateAccount');
    await expect(page.locator('script[data-mw-cookieconsent="captcah"]')).toHaveAttribute('type', 'text/plain');
    expect(requests).toHaveLength(0);
});

test('sign-up without a CAPTCHA token is rejected', async ({page}) => {
    await trackVendor(page);
    const name = 'CaptchaConsentTester' + Date.now();
    await page.goto('/wiki/Special:CreateAccount');
    // Dismiss the first-visit dialog without consent, it would cover the submit button
    await page.evaluate(() => mw.cookie.set('cookieconsent_dialog_dismissed', 'yes'));
    await page.reload();
    await page.locator('#wpName2').fill(name);
    await page.locator('#wpPassword2').fill('dockerpass-123!');
    await page.locator('#wpRetype').fill('dockerpass-123!');
    await page.locator('#wpCreateaccount').click();
    await expect(page.locator('#firstHeading')).not.toContainText('Welcome');
    await expect(page.locator('.mw-message-box-error, .cdx-message--error, .errorbox').first()).toBeVisible();
    // The account must not exist
    const res = await page.request.get('/w/api.php?action=query&list=users&ususers=' + name + '&format=json');
    expect(JSON.stringify(await res.json())).toContain('missing');
});

test('the guard module is registered as a VisualEditor plugin', async ({page}) => {
    await page.goto('/index.php?title=CaptchaConsentTest&veaction=edit');
    const state = await page.evaluate(() => mw.loader.getState('ext.captchaConsent'));
    expect(['loading', 'loaded', 'executing', 'ready']).toContain(state);
});

test('without CaptchaConsent loaded the page has no consent markup', async ({page, context}) => {
    await context.clearCookies();
    await page.goto('/wiki/Special:CreateAccount');
    await expect(page.locator('script[data-mw-cookieconsent]')).toHaveCount(0);
    await expect(page.locator('.mw-captchaconsent-notice')).toHaveCount(0);
});
