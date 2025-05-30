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

    await this.page.addScriptTag({
      url: 'https://cdn.jsdelivr.net/npm/defuddle@0.6.4'
    })

    const result = await this.page.evaluate(() => {
      // @ts-expect-error ignore this available in runtime
      const reader = new Defuddle(document)
      const article = reader.parse()

      let sanitizedContent = ''

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

        sanitizedContent = dom.body.innerHTML
      }

      const createdAt = article?.published?.split(',')?.[0]?.trim() ?? null

      function safeParseDate() {
        if (!createdAt) return null

        try {
          return new Date(createdAt).toISOString()
        } catch (_) {
          return null
        }
      }

      // TODO: here we can definitely do something with schema.org data
      return {
        content: sanitizedContent,
        title: article?.title ?? null,
        published_at: safeParseDate(),
        domain: article?.domain ?? null,
        actor: {
          name: article?.author ?? null
        }
      }
    })

    if (result.content) {
      const turndownService = new TurnDown({
        headingStyle: 'atx',
        codeBlockStyle: 'fenced'
      })

      result.content = turndownService.turndown(result.content)
    }

    return JSON.stringify({
      data: result
    })
  }
}
