import {test, expect, defineConfig} from '@playwright/test';

export default defineConfig({
    timeout: 5 * 60 * 1000,  // 5 minutes per test
});

test('can create an account', async ({page}) => {
    await page.goto('/wiki/Special:CreateAccount');

    // Username
    await expect(page.locator('#wpName2')).toHaveCount(1);
    await page.locator('#wpName2').fill( 'PlaywrightTester' );

    // Password
    await expect(page.locator('#wpPassword2')).toHaveCount(1);
    await page.locator('#wpPassword2').fill('dockerpass');

    // Password confirmation
    await expect(page.locator('#wpRetype')).toHaveCount(1);
    await page.locator('#wpRetype').fill('dockerpass');

    // Submit the form
    await expect(page.locator('#wpCreateaccount')).toHaveCount(1);
    await expect(page.locator('#wpCreateaccount')).toBeEnabled();
    await page.locator('#wpCreateaccount').click();

    // Check the user exists - use Special:MyPage redirect
    await page.goto('/wiki/Special:MyPage');
    await expect(page.locator('#firstHeading')).toContainText("User:PlaywrightTester");
});
