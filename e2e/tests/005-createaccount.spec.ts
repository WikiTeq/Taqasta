import {test, expect} from '@playwright/test';

// Ensure that a new account can be created - prevent conflicts on existing user
// names by using the time in the name
const time = Date.now();
const username = 'PlaywrightTester-' + time;

// Admin user that gets created by Taqasta
const ADMIN_USER_NAME = 'Admin';
const ADMIN_USER_PASS = 'rand0mmysqlpassw0rd1!';

test.describe.configure({ mode: 'serial' });

// Create `PlaywrightTester-{time}` user
test('can create an account', async ({page}) => {
    await page.goto('/wiki/Special:CreateAccount');

    // Username
    await expect(page.locator('#wpName2')).toBeVisible();
    await page.locator('#wpName2').fill( username );

    // Password
    await expect(page.locator('#wpPassword2')).toBeVisible();
    await page.locator('#wpPassword2').fill('dockerpass');

    // Password confirmation
    await expect(page.locator('#wpRetype')).toBeVisible();
    await page.locator('#wpRetype').fill('dockerpass');

    // Submit the form
    await expect(page.locator('#wpCreateaccount')).toBeVisible();
    await expect(page.locator('#wpCreateaccount')).toBeEnabled();
    await page.locator('#wpCreateaccount').click();

    // Check success message
    await expect(page.locator('#firstHeading')).toContainText("Welcome, " + username);

    // Use Special:MyPage to check the current user, will redirect to the
    // user page
    await page.goto('/wiki/Special:MyPage');
    await expect(page.locator('#firstHeading')).toContainText("User:" + username);
});

// From `Admin` grant `PlaywrightTester-{time}` sysop
test('can grant user rights', async ({page}) => {
    // Need to log in
    await page.goto('/wiki/Special:UserLogin');
    await page.locator('#wpName1').fill( ADMIN_USER_NAME );
    await page.locator('#wpPassword1').fill( ADMIN_USER_PASS );
    await page.locator('#wpLoginAttempt').click();

    // And now, the actual test
    await page.goto('/wiki/Special:UserRights/' + username );

    // Admin
    await expect(page.locator('#wpGroup-sysop')).toBeVisible();
    await page.locator('#wpGroup-sysop').check();

    // Reason
    await expect(page.locator('#wpReason')).toBeVisible();
    await page.locator('#wpReason').fill( 'Grant adminship' );

    // Submit the form
    await expect(page.locator('input[name="saveusergroups"]')).toBeVisible();
    await expect(page.locator('input[name="saveusergroups"]')).toBeEnabled();
    await page.locator('input[name="saveusergroups"]').click();
});

// from `PlaywrightTester-{time}` create and delete a page
test('can delete pages', async ({page}) => {
    // Need to log in
    await page.goto('/wiki/Special:UserLogin');
    await page.locator('#wpName1').fill( username );
    await page.locator('#wpPassword1').fill( 'dockerpass' );
    await page.locator('#wpLoginAttempt').click();

    // Create the page first
    await page.goto('/wiki/Deletion_test?action=edit');
    await expect(page.locator('#wpTextbox1')).toBeVisible();
    await page.locator('#wpTextbox1').fill('Some content');
    await expect(page.locator('#wpSave')).toBeVisible();
    await expect(page.locator('#wpSave')).toBeEnabled();
    await page.locator('#wpSave').click();

    // Go to delete page, should exist and have delete button
    await page.goto('/wiki/Deletion_test');
    await expect(page.locator('#mw-content-text')).toContainText('Some content');
    // Need to make the menu show up, otherwise element is not visible
    await expect(page.locator('#p-cactions-checkbox')).toBeVisible();
    await page.locator('#p-cactions-checkbox').check();
    await expect(page.locator('#ca-delete > a')).toBeVisible();
    await page.locator('#ca-delete > a').click();

    // Deletion form, use default reason
    await expect(page).toHaveTitle(/Delete "Deletion test"/);
    await expect(page.locator('button[name="wpConfirmB"]')).toBeVisible();
    await expect(page.locator('button[name="wpConfirmB"]')).toBeEnabled();
    await page.locator('button[name="wpConfirmB"]').click();

    // Go back to page, should be deleted
    await page.goto('/wiki/Deletion_test');
    // Not checking based on content text since the deletion logs have the text
    await expect(page.locator('.noarticletext')).toBeVisible();
    // Should have at least one log entry, allow multiple for running tests locally
    const logLocator = page.locator('ul.mw-logevent-loglines li.mw-logline-delete');
    await expect(logLocator.first()).toBeVisible();
    const logCount = await logLocator.count();
    expect(logCount).toBeGreaterThanOrEqual(1);
});
