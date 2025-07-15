import {test, expect} from '@playwright/test';

test('Anonymous user can upload a file', async ({page}) => {
    await page.goto('/wiki/Special:Upload');

    // To make sure that we are testing the upload and not just seeing an image
    // uploaded previously: upload to `Example-{time}.jpg` where {time} is
    // replaced with the current time - could only cause an issue with reusing
    // a file (and thus not actually testing the uploads) if the test is run
    // twice within a millisecond, which shouldn't be an issue.
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

    // Check the file page, should be sent there by the upload, unless
    // running in docker
    if ( process.env.TAQASTA_E2E_IN_DOCKER ) {
        await page.goto('/wiki/File:' + fileName);
    } else {
        await page.waitForURL('**/File:' + fileName);
    }
    await expect(page.locator('#mw-content-text')).toContainText("See commons:File:Example.jpg");
});
