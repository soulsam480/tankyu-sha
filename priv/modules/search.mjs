import { Source } from './source.mjs'

export class Search extends Source {
  get requiresLogin() {
    return false
  }

  get type() {
    return 'search'
  }

  async init() {
    await this.page.setExtraHTTPHeaders({
      Accept:
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Accept-Language': 'en-US,en;q=0.9',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
      Pragma: 'no-cache',
      'Sec-Ch-Ua': '"Google Chrome";v="123", "Not:A-Brand";v="8"',
      'Sec-Ch-Ua-Mobile': '?0',
      'Sec-Ch-Ua-Platform': '"Windows"',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Upgrade-Insecure-Requests': '1'
    })
  }

  /** @param {string} url */
  async process(url) {
    await this.page.goto(url, { waitUntil: 'networkidle' })

    await this.humanMouseMovement()
    await this.randomDelay(500, 1000)

    const { term = '' } = this.params

    if (!term) {
      throw new Error('No term provided')
    }

    await this.humanType(term)
    await this.humanMouseMovement()
    await this.randomDelay(20, 1000)
    await this.page.keyboard.press('Enter')

    await this.page.waitForSelector('.react-results--main')

    await this.randomDelay(20, 1000)

    const results = await this.page
      .locator('.react-results--main li[data-layout="organic"]')
      .all()

    const outcome = []

    for (const result of results) {
      const link = result.locator('a[target=_self]').nth(1)
      const header = await link.textContent()
      const href = await link.getAttribute('href')

      const description = await result
        .locator('[data-result="snippet"]')
        .textContent()

      outcome.push({
        link: href,
        header,
        description
      })
    }

    return JSON.stringify({ data: outcome })
  }
}
