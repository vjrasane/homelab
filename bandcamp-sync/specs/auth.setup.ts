import { expect } from "@playwright/test";
import { test as setup } from "../fixture";
import { authFile } from "../playwright.config";
import { existsSync } from "fs";

setup("auth", async ({ page, username, password }) => {
  setup.skip(existsSync(authFile));

  await page.goto("https://bandcamp.com/login");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Bandcamp/);
  await page.getByLabel("Username / email").fill(username);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Log in" }).click();

  await page.waitForURL("https://bandcamp.com/vjrasane");

  await page.context().storageState({ path: authFile });
});
