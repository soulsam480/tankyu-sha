export class Source {
	/**
	 * @param {import("playwright").Page} page
	 */
	constructor(page) {
		/**  @type {import("playwright").Page} */
		this.page = page;
	}

	/**
	 * @returns {string} url to login to this source
	 */
	get loginUrl() {
		throw new Error("Not implemented");
	}

	/**
	 * @returns {boolean} whether this source requires login
	 */
	get requiresLogin() {
		throw new Error("Not implemented");
	}

	/**
	 * @returns {string} type of this source
	 */
	get type() {
		throw new Error("Not implemented");
	}

	/**
	 * login to this source
	 */
	async login() {
		throw new Error("Not implemented");
	}

	/**
	 * run prep for this source
	 */
	async init() {
		if (this.requiresLogin) {
			await this.login();
		}
	}

	/**
	 * @param {string} _url process provided url
	 */
	async process(_url) {
		throw new Error("Not implemented");
	}
}
