import {test, expect} from '@playwright/test';

test('can edit a page', async ({page}) => {
    await page.goto('/');
    await expect(page.locator('#ca-edit > a')).toHaveCount(1);
    await page.locator('#ca-edit > a').click();
    await expect(page).toHaveTitle(/Editing/)
    await expect(page.locator('#wpTextbox1')).toHaveCount(1);
    await page.locator('#wpTextbox1').fill('u9es348923hjf8546344');
    await expect(page.locator('#wpSave')).toHaveCount(1);
    await expect(page.locator('#wpSave')).toBeEnabled();
    await page.locator('#wpSave').click();
    await expect(page.getByText('Your edit was saved.')).toHaveCount(1);
    await expect(page.locator('#mw-content-text')).toContainText(/u9es348923hjf8546344/);
});
