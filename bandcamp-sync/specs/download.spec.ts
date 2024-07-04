import { Locator, Page } from "@playwright/test";
import { nonEmptyString } from "decoders";
import Zip from "adm-zip";
import { existsSync, mkdir, mkdirSync, readdirSync, rm, statSync } from "fs";
import { join } from "path";
import { test } from "../fixture";
import chunk from "lodash/chunk";
import { promisify } from "util";

type AlbumDetails = {
  title: string;
  artist: string;
  downloadLink: Locator;
};

const getTextValue = async (locator: Locator): Promise<string> => {
  const content = await locator.evaluate((el) => el.firstChild?.textContent);
  return nonEmptyString.verify(content).trim();
};

const getAlbumDetails = async (album: Locator): Promise<AlbumDetails> => {
  const title = await getTextValue(
    album.locator(".collection-item-title").first(),
  );
  const artist = await getTextValue(
    album.locator(".collection-item-artist").first(),
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
    }),
  );
};

const downloadAlbum = async (
  page: Page,
  format: string,
  outputDir: string,
  album: AlbumDetails,
) => {
  const albumDir = join(outputDir, album.artist, album.title);
  if (existsSync(albumDir) && readdirSync(albumDir).length) {
    return;
  }

  await album.downloadLink.click();
  await page.selectOption("select", format.toLowerCase().replace(" ", "-"));
  const downloadEvent = page.waitForEvent("download");
  await page.getByRole("link", { name: "Download", exact: true }).click();
  const download = await downloadEvent;
  const filename = join(outputDir, download.suggestedFilename());
  await download.saveAs(filename);
  await promisify(mkdir)(albumDir, { recursive: true });
  await extractZip(filename, albumDir);
  await promisify(rm)(filename);
};

test("download", async ({ page, username, format, outputDir }) => {
  await page.goto("https://bandcamp.com/" + username);

  const albums = await page.locator(".collection-item-container").all();
  const details = await Promise.all(albums.map(getAlbumDetails));
  const batches = chunk();

  for (const album of details) {
    await downloadAlbum(page, format, outputDir, album);
    await page.goto("https://bandcamp.com/" + username);
  }
});
