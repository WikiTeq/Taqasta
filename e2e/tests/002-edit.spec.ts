import {test, expect} from '@playwright/test';

test('Anonymous user can edit a page', async ({page}) => {
    await page.goto('/wiki/Editing_test');
    await expect(page.locator('#ca-edit > a')).toBeVisible(1);
    await page.locator('#ca-edit > a').click();
    await expect(page).toHaveTitle(/Editing/)
    await expect(page.locator('#wpTextbox1')).toBeVisible();
    await page.locator('#wpTextbox1').fill('u9es348923hjf8546344');
    await expect(page.locator('#wpSave')).toBeVisible();
    await expect(page.locator('#wpSave')).toBeEnabled();
    await page.locator('#wpSave').click();
    // In docker the redirect is different
    if ( process.env.TAQASTA_E2E_IN_DOCKER ) {
        await page.goto('/wiki/Editing_test');
    } else {
        await page.waitForURL('**/wiki/Editing_test');
    }
    await expect(page.locator('#mw-content-text')).toContainText(/u9es348923hjf8546344/);
});
