import {test, expect} from '@playwright/test';

test('AJAXPoll renders a poll', async ({page}) => {
    const pageName = 'AJAXPoll_rendering_test_' + Date.now();

    // Create a new page with the poll syntax documented by AJAXPoll.
    await page.goto('/wiki/' + pageName + '?action=edit');
    await expect(page.locator('#wpTextbox1')).toBeVisible();
    await page.locator('#wpTextbox1').fill(`<poll>
Question
Choice 1
Choice 2
Choice 3
Choice 4
</poll>`);
    await expect(page.locator('#wpSave')).toBeEnabled();
    await page.locator('#wpSave').click();

    // Docker redirects differ from host-run redirects.
    if ( process.env.TAQASTA_E2E_IN_DOCKER ) {
        await page.goto('/wiki/' + pageName);
    } else {
        await page.waitForURL('**/wiki/' + pageName);
    }

    const poll = page.locator('.ajaxpoll');
    await expect(poll).toHaveCount(1);
    await expect(poll.locator('.ajaxpoll-question')).toHaveText('Question');
    await expect(poll.locator('.ajaxpoll-answer-name label')).toHaveText([
        'Choice 1',
        'Choice 2',
        'Choice 3',
        'Choice 4',
    ]);
});
