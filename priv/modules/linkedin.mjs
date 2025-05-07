import { Source } from "./source.mjs";

const PROFILE_REGEXP = /^\/(?:in|pub)\/(?<handle>[\w\-À-ÿ%]+)\/?/i;

const COMPANY_REGEXP =
	/^\/(?:company|school)\/(?<handle>[A-Za-z0-9\-À-ÿ\.]+)\/?/i;

/**
 * @typedef {Object} Post
 * @property {string} content - post content
 * @property {number} [id] - post id
 */

export class Linkedin extends Source {
	get requiresLogin() {
		return true;
	}

	get type() {
		return "linked_in";
	}

	get loginUrl() {
		return "https://www.linkedin.com/uas/login";
	}

	async login() {
		await this.page.goto(this.loginUrl, {
			waitUntil: "load",
		});

		await this.page.waitForSelector('input[name="session_key"]');

		await this.page
			.locator('input[name="session_key"]')
			.fill(process.env.LINKEDIN_EMAIL);

		await this.page
			.locator('input[name="session_password"]')
			.fill(process.env.LINKEDIN_PASSWORD);

		await this.page.locator('[type="submit"]').click();

		await this.page.waitForSelector(".global-nav__content");
	}

	/**
	 * @param {string} url process provided url
	 */
	async process(url) {
		const profilePath = this.#getFeedPath(url);

		if (!profilePath) {
			throw new Error(JSON.stringify({ type: "UNKNOWN_LINKEDIN_KIND" }));
		}

		const { hostname } = new URL(url);

		const feedUrl = `https://${hostname}${profilePath}`;

		await this.page.goto(feedUrl);

		const posts = await this.#getPosts();

		return JSON.stringify({ data: posts });
	}

	/**
	 * @param {string} url
	 */
	#getPageKind(url) {
		const { pathname } = new URL(url);

		if (PROFILE_REGEXP.test(pathname)) {
			return "profile";
		}

		if (COMPANY_REGEXP.test(pathname)) {
			return "company";
		}

		return "unknown";
	}

	/**
	 * @param {string} url
	 */
	#getFeedPath(url) {
		const kind = this.#getPageKind(url);
		const { pathname } = new URL(url);

		switch (kind) {
			case "profile": {
				const handle = pathname.match(PROFILE_REGEXP).groups?.handle;

				if (!handle) {
					throw new Error(JSON.stringify({ type: "UNKNOWN_PROFILE" }));
				}

				return `/in/${handle}/recent-activity/all`;
			}
			case "company": {
				const handle = pathname.match(COMPANY_REGEXP).groups?.handle;

				if (!handle) {
					throw new Error(JSON.stringify({ type: "UNKNOWN_COMPANY" }));
				}

				return `/company/${handle}/posts/?feedView=all`;
			}
			default:
				return null;
		}
	}

	async #getPosts() {
		await this.page.waitForSelector("[role=article]");

		const articles = await this.page.locator("[role=article]").all();

		/** @type {Post[]} */
		const posts = [];

		let count = 1;

		for (const article of articles) {
			const showMore = article.locator("button[class*='show-more']");

			if (await showMore.isVisible()) {
				await showMore.click();
			}

			const postText = await article
				.locator(".update-components-text")
				.textContent();

			if (postText) {
				posts.push({
					id: count++,
					content: postText,
				});
			}
		}

		return posts;
	}
}
