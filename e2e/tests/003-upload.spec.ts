import {test, expect, defineConfig} from '@playwright/test';

export default defineConfig({
    timeout: 5 * 60 * 1000,  // 5 minutes per test
});

test('can upload a file', async ({page}) => {
    await page.goto('/wiki/Special:Upload');

    // Actual file
    await expect(page.locator('#wpUploadFile')).toHaveCount(1);
    await page.locator('#wpUploadFile').setInputFiles( './fixtures/Example.jpg' );

    // Name
    await expect(page.locator('#wpDestFile')).toHaveCount(1);
    await page.locator('#wpDestFile').fill('Example.jpg');

    // Description
    await expect(page.locator('#wpUploadDescription')).toHaveCount(1);
    await page.locator('#wpUploadDescription').fill('See [[:commons:File:Example.jpg]]');

    // Submit the upload
    await expect(page.locator('input[name="wpUpload"]')).toHaveCount(1);
    await expect(page.locator('input[name="wpUpload"]')).toBeEnabled();
    await page.locator('input[name="wpUpload"]').click();

    // Check the file page
    await page.goto('/wiki/File:Example.jpg');
    await expect(page.locator('#mw-content-text')).toContainText("See commons:File:Example.jpg");
});
