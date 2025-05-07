import { chromium } from "playwright-extra";
import StealthPlugin from "puppeteer-extra-plugin-stealth";
import dotenv from "dotenv";
import { Linkedin } from "./modules/linkedin.mjs";

dotenv.config();

chromium.use(StealthPlugin());

const SOURCE_TO_CTOR = {
	LinkedIn: Linkedin,
};

async function main() {
	try {
		const url = process.argv[2];
		const kind = process.argv[3] || null;

		if (!url) {
			// return JSON.stringify({ error: { type: "NO_URL" } });
			console.log(JSON.stringify({ error: { type: "NO_URL" } }));
			return;
		}

		const browser = await chromium.launch({
			slowMo: 500,
			headless: false,
			executablePath: "/Applications/Chromium.app/Contents/MacOS/Chromium",
		});

		const context = await browser.newContext();

		const page = await context.newPage();

		async function close() {
			await page.close();
			await context.close();
			await browser.close();
		}

		if (!kind) {
			// TODO: any kind process

			await close();
			// return JSON.stringify({ data: [] });
			console.log(JSON.stringify({ data: [] }));
		}

		const Ctor = SOURCE_TO_CTOR[kind];

		if (!Ctor) {
			await close();
			// return JSON.stringify({ error: { type: "UNKNOWN_SOURCE" } });
			console.log(JSON.stringify({ error: { type: "UNKNOWN_SOURCE" } }));
		}

		/**  @type {import("./modules/source.mjs").Source} */
		const source = new Ctor(page);

		await source.init();

		const response = await source.process(url);

		await close();

		// return response;
		console.log(response);
	} catch (e) {
		console.log(e);
		// return JSON.stringify({
		// 	error: {
		// 		type: "PROCESS_ERROR",
		// 		details: JSON.stringify(e),
		// 	},
		// });
		console.log(
			JSON.stringify({
				error: {
					type: "PROCESS_ERROR",
					details: JSON.stringify(e),
				},
			}),
		);
	}
}

main();
