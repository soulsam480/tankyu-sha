import type { BrowserContext, Page, Locator } from 'playwright'

export class Source {
  // @ts-expect-error ignore
  page: Page
  context: BrowserContext
  params: Record<string, string>

  constructor(context: BrowserContext, params: Record<string, string>) {
    this.context = context
    this.params = params
  }

  async newPage(height: number = 1080, width: number = 1920): Promise<Page> {
    const page = await this.context.newPage()

    await page.setViewportSize({
      height,
      width
    })

    return page
  }

  async runLocatorIfVisible<T>(
    loc: Locator,
    cb: (loc: Locator) => Promise<T>
  ): Promise<T | null> {
    if (await loc.isVisible()) {
      return await cb(loc)
    }

    return null
  }

  get loginUrl(): string {
    throw new Error('Not implemented')
  }

  get requiresLogin(): boolean {
    throw new Error('Not implemented')
  }

  get type(): string {
    throw new Error('Not implemented')
  }

  async login(): Promise<void> {
    throw new Error('Not implemented')
  }

  async createDefaultPage(): Promise<void> {
    if (!this.page) {
      this.page = await this.newPage()

      this.page.setViewportSize({
        height: 1080,
        width: 1920
      })
    }
  }

  async init(): Promise<void> {
    await this.createDefaultPage()

    if (this.requiresLogin) {
      await this.login()
    }
  }

  async process(_url: string): Promise<any> {
    throw new Error('Not implemented')
  }

  async humanMouseMovement(): Promise<void> {
    // Move mouse randomly
    await this.page.mouse.move(
      100 + Math.floor(Math.random() * 100),
      100 + Math.floor(Math.random() * 100),
      { steps: 10 }
    )
  }

  async randomDelay(min: number = 500, max: number = 2000): Promise<void> {
    const delay = Math.floor(Math.random() * (max - min) + min)
    await this.page.waitForTimeout(delay)
  }

  async humanType(text: string): Promise<void> {
    for (const char of text) {
      await this.page.keyboard.type(char, {
        delay: 10 + Math.random() * 200
      })
    }
  }
}
