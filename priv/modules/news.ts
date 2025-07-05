import { Source } from './source.ts'
import TurnDown from 'turndown'

interface Article {
  content?: string
  title?: string
  published?: string
  domain?: string
  author?: string
}

interface Defuddle {
  parse(): Article
}

export class News extends Source {
  get type(): string {
    return 'news'
  }

  get requiresLogin(): boolean {
    return false
  }

  async process(url: string): Promise<string> {
    await this.page.goto(url, { waitUntil: 'domcontentloaded' })

    await this.page.addScriptTag({
      url: 'https://cdn.jsdelivr.net/npm/defuddle@0.6.4'
    })

    const result = await this.page.evaluate(() => {
      // @ts-expect-error ignore this available in runtime
      const reader: Defuddle = new Defuddle(document)
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

      function safeParseDate(): string | null {
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
