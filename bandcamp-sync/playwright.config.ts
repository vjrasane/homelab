import { defineConfig, devices } from "@playwright/test";

import "dotenv/config";
import { Options } from "./fixture";
import { join } from "path";

const { BANDCAMP_USERNAME, BANDCAMP_PASSWORD, OUTPUT_DIR, FORMAT } =
  process.env;

export const authFile = join(__dirname, "playwright", ".auth", "user.json");

export default defineConfig<Options>({
  testDir: "./specs",
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: "html",
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://127.0.0.1:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: "on-first-retry",
    username: BANDCAMP_USERNAME,
    password: BANDCAMP_PASSWORD,
    outputDir: OUTPUT_DIR,
    format: FORMAT,
  },

  /* Configure projects for major browsers */
  projects: [
    { name: "setup", testMatch: /.*\.setup\.ts/ },
    {
      name: "download",
      testMatch: "download.spec.ts",
      use: { ...devices["Desktop Chrome"], storageState: authFile },
      dependencies: ["setup"],
    },
  ],
});
