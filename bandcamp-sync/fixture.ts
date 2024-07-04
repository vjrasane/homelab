import { test as base } from "@playwright/test";
import { join } from "path";

export type Options = {
  username: string;
  password: string;
  format: string;
  batchSize: number;
  outputDir: string;
};

export const test = base.extend<Options>({
  username: ["", { option: true }],
  password: ["", { option: true }],
  format: ["MP3 V0", { option: true }],
  batchSize: [3, { option: true }],
  outputDir: [join(__dirname, "playwright", ".download"), { option: true }],
});
