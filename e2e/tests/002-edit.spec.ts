import {test, expect, defineConfig} from '@playwright/test';

export default defineConfig({
    timeout: 5 * 60 * 1000,  // 5 minutes per test
});

test('can edit a page', async ({page}) => {
    await page.goto('/wiki/Editing_test');
    await expect(page.locator('#ca-edit > a')).toHaveCount(1);
    await page.locator('#ca-edit > a').click();
    await expect(page).toHaveTitle(/Editing/)
    await expect(page.locator('#wpTextbox1')).toHaveCount(1);
    await page.locator('#wpTextbox1').fill('u9es348923hjf8546344');
    await expect(page.locator('#wpSave')).toHaveCount(1);
    await expect(page.locator('#wpSave')).toBeEnabled();
    await page.locator('#wpSave').click();
    // Locally the save button goes to the wrong place?
    await page.goto('/wiki/Editing_test');
    await expect(page.locator('#mw-content-text')).toContainText(/u9es348923hjf8546344/);
});
