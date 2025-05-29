export class Source {
  /** @type {import("playwright").Page} */
  // @ts-expect-error ignore
  page
  /** @type {import("playwright").BrowserContext} */
  context
  /** @type {Record<string,string>} */
  params

  /**
   * @param {import("playwright").BrowserContext} page
   * @param {Record<string, string>} params
   */
  constructor(page, params) {
    /**  @type {import("playwright").BrowserContext} */
    this.context = page
    /** @type {Record<string,string>} */
    this.params = params
  }

  /** @returns {Promise<import("playwright").Page>} */
  async newPage(height = 1080, width = 1920) {
    const page = await this.context.newPage()

    await page.setViewportSize({
      height,
      width
    })

    return page
  }

  /**
   * @param {import("playwright").Locator} loc
   * @param {(loc: import("playwright").Locator) => Promise<T>} cb
   * @template T
   * @returns {Promise<T | null>}
   */
  async runLocatorIfVisible(loc, cb) {
    if (await loc.isVisible()) {
      return await cb(loc)
    }

    return null
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

  async createDefaultPage() {
    if (!this.page) {
      this.page = await this.newPage()

      this.page.setViewportSize({
        height: 1080,
        width: 1920
      })
    }
  }

  /**
   * run prep for this source
   */
  async init() {
    await this.createDefaultPage()

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
      100 + Math.floor(Math.random() * 100),
      100 + Math.floor(Math.random() * 100),
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
      await this.page.keyboard.type(char, {
        delay: 10 + Math.random() * 200
      })
    }
  }
}
