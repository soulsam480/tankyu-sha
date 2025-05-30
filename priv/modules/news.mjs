import { Source } from './source.mjs'
import TurnDown from 'turndown'

/**
 * @see https://github.com/n4ze3m/page-assist/blob/main/src/loader/html.ts#L20
 * this piece has been taken from page-assist
 */
export class News extends Source {
  get type() {
    return 'news'
  }

  get requiresLogin() {
    return false
  }

  /**
   * @param {string} url process provided url
   */
  async process(url) {
    await this.page.goto(url, { waitUntil: 'domcontentloaded' })

    await Promise.all([
      this.page.addScriptTag({
        url: 'https://cdn.jsdelivr.net/npm/@mozilla/readability@0.6.0/Readability.min.js'
      }),
      this.page.addScriptTag({
        url: 'https://cdn.jsdelivr.net/npm/@mozilla/readability@0.6.0/Readability-readerable.js'
      })
    ])

    const content = await this.page.evaluate(() => {
      // @ts-expect-error ignore this available in runtime
      if (isProbablyReaderable(document)) {
        // @ts-expect-error ignore this available in runtime
        const reader = new Readability(document)
        const article = reader.parse()

        if (article && article.content) {
          const dom = new DOMParser().parseFromString(
            article.content,
            'text/html'
          )

          dom
            .querySelectorAll("script, style, link, svg, [src^='data:image/']")
            .forEach(it => {
              it.remove()
            })

          return dom.body.innerHTML
        }

        document
          .querySelectorAll("script, style, link, svg, [src^='data:image/']")
          .forEach(el => {
            el.remove()
          })

        document.querySelectorAll('*').forEach(element => {
          if ('attribs' in element) {
            const attributes = element.attributes

            for (const attr in attributes) {
              if (attr !== 'href' && attr !== 'src') {
                element.removeAttribute(attr)
              }
            }
          }
        })

        const mainContent =
          document.querySelector('[role="main"]')?.innerHTML ||
          document.querySelector('main')?.innerHTML ||
          document.querySelector('article')?.innerHTML ||
          ''

        return mainContent
      }
    })

    const turndownService = new TurnDown({
      headingStyle: 'atx',
      codeBlockStyle: 'fenced'
    })

    const markdown = turndownService.turndown(content ?? '')

    return JSON.stringify({
      data: {
        content: markdown
      }
    })
  }
}
