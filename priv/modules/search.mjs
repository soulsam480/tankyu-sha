import { RunnerError } from '../lib/error.mjs'
import { Source } from './source.mjs'
// @ts-expect-error no types
import { harvestPageAll } from 'js-harvester/playwright.js'
// @ts-expect-error no types
import fixTime from 'fix-time'

export class Search extends Source {
  get requiresLogin() {
    return false
  }

  get type() {
    return 'search'
  }

  async init() {
    await this.createDefaultPage()

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

    const { term = '', pages: _pages = '1' } = this.params

    const pages = Number(_pages)

    if (term) {
      await this.humanType(term)
      await this.humanMouseMovement()
      await this.page.keyboard.press('Enter')
    }

    const pageURL = new URL(this.page.url())

    const section = pageURL.searchParams.get('ia') ?? 'web'

    switch (section) {
      case 'news':
        await this.page.waitForSelector('article section ol')
        break

      case 'web':
        await this.page.waitForSelector('.react-results--main')
        break

      default:
        throw new RunnerError({
          type: 'InvalidSection',
          details: `${section} is not a valid section`
        })
    }

    await this.#paginate(pages, section)

    switch (section) {
      case 'news':
        return await this.#fetchNewsResults()

      default:
        return await this.#fetchSearchResults()
    }
  }

  async #fetchNewsResults() {
    const resultTpl = `
li
  a[link=href]
    *
      h2{title}
      div
        div
          span{publisher}
        div{published_at}
      div
        p{description:str}`

    const results = await harvestPageAll(
      this.page,
      resultTpl,
      'article section ol li',
      {
        dataOnly: true,
        inject: true
      }
    )

    return JSON.stringify({
      // @ts-expect-error ignore types here
      data: results.map(({ published_at: at, description, ...rest }, index) => {
        return {
          ...rest,
          id: index.toString(),
          published_at: fixTime(at).toISOString(),
          description: Array.isArray(description)
            ? description.join(' ')
            : description
        }
      })
    })
  }

  async #fetchSearchResults() {
    const results = await this.page
      .locator('.react-results--main li[data-layout="organic"]')
      .all()

    const outcome = await Promise.all(
      results.map(async (result, i) => {
        const link = result.locator('a[target=_self]').nth(1)
        const title = await link.textContent()
        const href = await link.getAttribute('href')

        const description = await result
          .locator('[data-result="snippet"]')
          .textContent()

        return {
          id: i.toString(),
          link: href,
          title,
          description
        }
      })
    )

    return JSON.stringify({ data: outcome })
  }

  /**
   * @param {number} pages
   * @param {string} section
   */
  async #paginate(pages, section) {
    if (pages > 1) {
      for (let page = 1; page <= pages; page++) {
        switch (section) {
          case 'news':
            {
              const loc = this.page
                .getByRole('button', {
                  name: /load\smore/i
                })
                .first()

              if (await loc.isVisible()) {
                await loc.click()
              }

              await this.page.waitForResponse(url => {
                return url.url().includes('links.duckduckgo.com/news.js')
              })
            }

            break

          default: {
            const loc = this.page
              .getByRole('button', {
                name: /more\sresults/i
              })
              .first()

            if (await loc.isVisible()) {
              await loc.click()
            }

            await this.page.waitForResponse(url => {
              return url.url().includes('links.duckduckgo.com/d.js')
            })
          }
        }
      }
    }
  }
}
