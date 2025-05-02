import {test, expect} from '@playwright/test';

// Admin user that gets created by Taqasta
const ADMIN_USER_NAME = 'Admin';
const ADMIN_USER_PASS = 'rand0mmysqlpassw0rd1!';

test('can log in to existing account', async ({page}) => {
    await page.goto('/wiki/Special:UserLogin');

    // Username
    await expect(page.locator('#wpName1')).toBeVisible();
    await page.locator('#wpName1').fill( ADMIN_USER_NAME );

    // Password
    await expect(page.locator('#wpPassword1')).toBeVisible();
    await page.locator('#wpPassword1').fill( ADMIN_USER_PASS );

    // Submit the form
    await expect(page.locator('#wpLoginAttempt')).toBeVisible();
    await expect(page.locator('#wpLoginAttempt')).toBeEnabled();
    await page.locator('#wpLoginAttempt').click();

    // Check the login - use Special:MyPage redirect to confirm that we are the
    // correct user
    await page.goto('/wiki/Special:MyPage');
    await expect(page.locator('#firstHeading')).toContainText("User:" + ADMIN_USER_NAME);
});
