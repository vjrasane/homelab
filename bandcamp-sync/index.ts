import {
  Page,
  Browser,
  BrowserContext,
  BrowserContextOptions,
  Locator,
  devices,
} from "playwright";
import { chromium } from "playwright-extra";
import stealth from "puppeteer-extra-plugin-stealth";
import { join } from "node:path";
import Zip from "adm-zip";
import { existsSync, mkdir, readdir, rm, statSync } from "node:fs";
import { promisify } from "node:util";
import chunk from "lodash.chunk";

import "dotenv/config";

const { BANDCAMP_USERNAME, BANDCAMP_PASSWORD, OUTPUT_DIR, FORMAT, BATCH_SIZE } =
  process.env;
const { HEADLESS = "false" } = process.env;

const MAX_STORAGE_AGE_MILLIS = 24 * 60 * 60 * 1000;

const playwrighDir = join(__dirname, "playwright");
const storageStateFile = join(playwrighDir, "storageState.json");

const headless = HEADLESS === "true";
const outputDir = OUTPUT_DIR ?? join(playwrighDir, "output");
const format = FORMAT ?? "MP3 V0";
const collectionPagePath = "./" + BANDCAMP_USERNAME!;
const batchSize = parseInt(BATCH_SIZE ?? "3");

console.log("Output dir: " + outputDir);

const getContext = async (browser: Browser, opts?: BrowserContextOptions) => {
  const context = browser.newContext({
    ...devices["Desktop Chrome"],
    baseURL: "https://bandcamp.com",
    ...(opts ?? {}),
  });
  return context;
};

const login = async (browser: Browser): Promise<BrowserContext> => {
  const context = await getContext(browser);
  const page = await context.newPage();
  await page.goto("https://bandcamp.com/login");

  await page.getByLabel("Username / email").fill(BANDCAMP_USERNAME!);
  await page.getByLabel("Password").fill(BANDCAMP_PASSWORD!);
  await page.getByRole("button", { name: "Log in" }).click();

  await page.waitForURL("https://bandcamp.com/vjrasane");

  await page.context().storageState({ path: storageStateFile });
  return context;
};

const getAuthContext = async (browser: Browser): Promise<BrowserContext> => {
  if (!existsSync(storageStateFile)) return login(browser);
  const { ctime } = statSync(storageStateFile);
  if (Date.now() - ctime.getTime() > MAX_STORAGE_AGE_MILLIS)
    return login(browser);
  return getContext(browser, { storageState: storageStateFile });
};
type AlbumDetails = {
  title: string;
  artist: string;
  downloadLink: Locator;
};

const getTextValue = async (locator: Locator): Promise<string> => {
  const content = await locator.evaluate((el) => el.firstChild?.textContent);
  if (!content) throw new Error("Invalid content for locator " + locator);
  return content.trim();
};

const getAlbumDetails = async (album: Locator): Promise<AlbumDetails> => {
  const title = await getTextValue(
    album.locator(".collection-item-title").first()
  );
  const artist = await getTextValue(
    album.locator(".collection-item-artist").first()
  );
  const downloadLink = album.getByRole("link", {
    name: "download",
    exact: true,
  });

  return {
    title,
    artist: artist.startsWith("by ") ? artist.substring("by ".length) : artist,
    downloadLink,
  };
};

const extractZip = (archiveFile: string, targetDir: string) => {
  return new Promise((resolve, reject) =>
    new Zip(archiveFile).extractAllToAsync(targetDir, true, true, (error) => {
      if (error) reject(error);
      resolve(undefined);
    })
  );
};
const getAlbumDir = (album: AlbumDetails) => {
  const albumDir = join(outputDir, album.artist, album.title);
  return albumDir;
};

const isAlbumDowloaded = async (album: AlbumDetails) => {
  const albumDir = getAlbumDir(album);
  if (!existsSync(albumDir)) return false;
  if (!(await promisify(readdir)(albumDir)).length) return false;
  return true;
};

const downloadAlbum = async (page: Page, album: AlbumDetails) => {
  await page
    .locator(".collection-item-container")
    .filter({ hasText: album.title })
    .filter({ hasText: album.artist })
    .getByRole("link", { name: "download" })
    .click();

  await page.selectOption("select", format.toLowerCase().replace(" ", "-"));
  const downloadEvent = page.waitForEvent("download");
  await page.getByRole("link", { name: "Download", exact: true }).click();
  const download = await downloadEvent;
  const filename = join(outputDir, download.suggestedFilename());
  await download.saveAs(filename);
  const albumDir = getAlbumDir(album);
  await promisify(mkdir)(albumDir, { recursive: true });
  await extractZip(filename, albumDir);
  await promisify(rm)(filename);
};

const main = async () => {
  chromium.use(stealth());

  const browser = await chromium.launch({ headless });
  const context = await getAuthContext(browser);
  const page = await context.newPage();

  if (headless) await context.route("**.jpg", (route) => route.abort());

  await page.goto(collectionPagePath);

  const albums = await page.locator(".collection-item-container").all();
  const details = await Promise.all(albums.map(getAlbumDetails));
  const batches = chunk(details, batchSize);

  for (const batch of batches) {
    await Promise.all(
      batch.map(async (album) => {
        if (await isAlbumDowloaded(album)) {
          console.log(`Already downloaded: ${album.artist} - ${album.title}`);
          return;
        }
        const page = await context.newPage();
        page.setDefaultTimeout(5000);
        await page.goto(collectionPagePath);
        console.log(`Downloading: ${album.artist} - ${album.title}`);
        await downloadAlbum(page, album);
        console.log(`Finished: ${album.artist} - ${album.title}`);
        await page.close();
      })
    );
  }

  await context.close();
  await browser.close();
};

main();
