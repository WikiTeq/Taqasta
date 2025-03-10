import {test, expect} from '@playwright/test';

test('Anonymous user can upload a file', async ({page}) => {
    await page.goto('/wiki/Special:Upload');

    // To make sure that we are testing the upload and not just seeing an image
    // uploaded previously: upload to `Example-{time}.jpg` where {time} is
    // replaced with the current time - can only reuse the same name if the
    // test is run twice within a millisecond
    const time = Date.now();
    const fileName = 'Example-' + time + '.jpg';

    // Actual file
    await expect(page.locator('#wpUploadFile')).toBeVisible();
    await page.locator('#wpUploadFile').setInputFiles( './fixtures/Example.jpg' );

    // Name
    await expect(page.locator('#wpDestFile')).toBeVisible();
    await page.locator('#wpDestFile').fill(fileName);

    // Description
    await expect(page.locator('#wpUploadDescription')).toBeVisible();
    await page.locator('#wpUploadDescription').fill('See [[:commons:File:Example.jpg]]');

    // Suppress warning about duplicates
    await expect(page.locator('input[name="wpIgnoreWarning"]')).toBeVisible();
    await expect(page.locator('input[name="wpIgnoreWarning"]')).toBeEnabled();
    await page.locator('input[name="wpIgnoreWarning"]').check();

    // Submit the upload
    await expect(page.locator('input[name="wpUpload"]')).toBeVisible();
    await expect(page.locator('input[name="wpUpload"]')).toBeEnabled();
    await page.locator('input[name="wpUpload"]').click();

    // Check the file page, should be sent there by the upload, except that
    // the wiki will redirect to http://localhost:8000/... and from within the
    // e2e container, the wiki is not at http://localhost:8000/, but rather at
    // http://web/ and the redirect to localhost will be an error, need to
    // manually get back to the wiki
    await page.goto('/wiki/File:' + fileName);
    await expect(page.locator('#mw-content-text')).toContainText("See commons:File:Example.jpg");
});
