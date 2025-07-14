import { defineConfig, devices } from '@playwright/test';

let htmlReporter = 'html';
let baseURL = 'http://localhost:8000';
if ( process.env.TAQASTA_E2E_IN_DOCKER ) {
  htmlReporter = [ [ 'html', { open: 'never'}] ];
  baseURL = 'http://web:80/';
}

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  /* Run tests in files in parallel */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* No retries */
  retries: 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : 1,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: htmlReporter,
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: baseURL,
    /* Keep traces for failed tests. See https://playwright.dev/docs/trace-viewer */
    trace: 'retain-on-failure',
    /* Screenshot, see https://playwright.dev/docs/api/class-testoptions#test-options-screenshot */
    screenshot: 'only-on-failure',
    /* https://playwright.dev/docs/api/class-testoptions#test-options-navigation-timeout */
    navigationTimeout: 60000,
  },

  // global timeout per suite
  globalTimeout: 60 * 60 * 1000,

  /* 5 minutes per test */
  timeout: 5 * 60 * 1000,

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

});
