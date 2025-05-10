export class Source {
  /**
   * @param {import("playwright").Page} page
   * @param {Record<string, string>} params
   */
  constructor(page, params) {
    /**  @type {import("playwright").Page} */
    this.page = page
    /** @type {Record<string,string>} */
    this.params = params
  }

  /**
   * @returns {string} url to login to this source
   */
  get loginUrl() {
    throw new Error('Not implemented')
  }

  /**
   * @returns {boolean} whether this source requires login
   */
  get requiresLogin() {
    throw new Error('Not implemented')
  }

  /**
   * @returns {string} type of this source
   */
  get type() {
    throw new Error('Not implemented')
  }

  /**
   * login to this source
   */
  async login() {
    throw new Error('Not implemented')
  }

  /**
   * run prep for this source
   */
  async init() {
    if (this.requiresLogin) {
      await this.login()
    }
  }

  /**
   * @param {string} _url process provided url
   * @returns {Promise<unknown>}
   */
  async process(_url) {
    throw new Error('Not implemented')
  }

  async humanMouseMovement() {
    // Move mouse randomly
    await this.page.mouse.move(
      100 + Math.floor(Math.random() * 500),
      100 + Math.floor(Math.random() * 500),
      { steps: 10 }
    )
  }

  async randomDelay(min = 500, max = 2000) {
    const delay = Math.floor(Math.random() * (max - min) + min)
    await this.page.waitForTimeout(delay)
  }

  /**
   * @param {string} text
   */
  async humanType(text) {
    for (const char of text) {
      await this.page.keyboard.type(char, { delay: 100 + Math.random() * 200 })
    }
  }
}
