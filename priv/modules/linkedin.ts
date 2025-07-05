import { Source } from './source.ts'
// @ts-ignore ignore
import { harvestPage } from 'js-harvester/playwright.js'
import { LinkedInUrlInfo } from './linkedin-url-info.ts'
import { RunnerError } from '../lib/error.ts'
import type { Page, Locator } from 'playwright'

interface Post {
  content: string
  id?: number
  unique_id: string
  actor: Record<string, string>
  time_ago: string
  images: string[]
}

export class Linkedin extends Source {
  get requiresLogin(): boolean {
    return false
  }

  get type(): string {
    return 'linked_in'
  }

  get loginUrl(): string {
    return 'https://www.linkedin.com/uas/login'
  }

  async login(): Promise<void> {
    await this.page.goto(this.loginUrl, {
      waitUntil: 'load'
    })

    await this.humanMouseMovement()

    await this.randomDelay(0, 100)

    await this.page.waitForSelector('input[name="session_key"]')

    await this.page.locator('input[name="session_key"]').focus()

    await this.randomDelay(0, 100)

    await this.humanType(process.env.LINKEDIN_EMAIL || '')

    await this.randomDelay(0, 100)

    await this.page.locator('input[name="session_password"]').focus()

    await this.humanType(process.env.LINKEDIN_PASSWORD || '')

    await this.randomDelay(0, 100)

    await this.humanMouseMovement()

    await this.page.keyboard.press('Enter')

    await this.page.waitForSelector('.global-nav__content')
  }

  async process(url: string): Promise<string> {
    const urlInfo = new LinkedInUrlInfo(url)

    if (urlInfo.isUnknown) {
      throw new RunnerError({
        type: 'UNKNOWN_LINKEDIN_KIND',
        details: 'Unknown LinkedIn kind is not available.'
      })
    }

    if (urlInfo.isStandalonePost) {
      return this.#processPost(urlInfo)
    }

    return this.#processFeed(urlInfo)
  }

  async #processPost(urlInfo: LinkedInUrlInfo): Promise<string> {
    await this.page.goto(urlInfo.originalUrl, {
      waitUntil: 'domcontentloaded'
    })

    if (!(await this.#loginCheck())) {
      await this.page.goto(urlInfo.originalUrl, {
        waitUntil: 'domcontentloaded'
      })
    }

    await this.page.addScriptTag({
      url: 'https://unpkg.com/js-harvester@0.3.14/src/harvester.js'
    })

    await this.page.waitForSelector('[role="article"]')

    const posts: Post[] = []

    let post: Post | null = await this.#fetchPost(
      this.page.locator('[role="article"]').first()
    )

    if (post) {
      post.id = 1
      posts.push(post)
    }

    return JSON.stringify({
      data: {
        company_info: null,
        posts
      }
    })
  }

  async #processFeed(urlInfo: LinkedInUrlInfo): Promise<string> {
    if (!urlInfo.feedUrl) {
      throw new RunnerError({
        type: 'INVALID_FEED_URL',
        details: 'Feed URL is not available in urlInfo.'
      })
    }

    await this.page.goto(urlInfo.feedUrl)

    await this.#loginCheck()

    const promises: Promise<any>[] = []

    if (urlInfo.isCompany) {
      promises.push(this.#getCompanyAboutInfo(urlInfo))
    } else {
      promises.push(Promise.resolve(null))
    }

    promises.push(this.#getPosts(urlInfo))

    const [companyInfo, posts] = await Promise.all(promises)

    return JSON.stringify({
      data: {
        posts,
        company_info: companyInfo
      }
    })
  }

  async #getPosts(
    urlInfo: LinkedInUrlInfo,
    page: Page | null = null
  ): Promise<Post[]> {
    page ??= await this.newPage()

    if (!urlInfo.feedUrl) {
      throw new RunnerError({
        type: 'INVALID_FEED_URL',
        details: 'Feed URL is not available in urlInfo.'
      })
    }

    await page.goto(urlInfo.feedUrl, {
      waitUntil: 'domcontentloaded'
    })

    await page.waitForSelector('[role="article"]')

    const rows: Locator[] = await page.locator('[role="article"]').all()

    await page.addScriptTag({
      url: 'https://unpkg.com/js-harvester@0.3.14/src/harvester.js'
    })

    const posts: Post[] = []

    for (let index = 0; index < 10; index++) {
      const el: Locator | undefined = rows[index]

      if (!el) {
        continue
      }

      await el.scrollIntoViewIfNeeded()

      const post = await this.#fetchPost(el)

      if (!post) {
        continue
      }

      posts.push({
        ...post,
        id: index + 1
      })
    }

    return posts
  }

  async #getCompanyAboutInfo(urlInfo: LinkedInUrlInfo): Promise<any> {
    if (!urlInfo.companyAboutUrl) {
      throw new RunnerError({
        type: 'INVALID_COMPANY_ABOUT_URL',
        details: 'Company about URL is not available in urlInfo.'
      })
    }

    await this.page.goto(urlInfo.companyAboutUrl, {
      waitUntil: 'domcontentloaded'
    })

    await Promise.all([
      this.page.waitForSelector("div[class*='org-top-card__primary']", {
        timeout: 7000
      }),
      this.page.waitForSelector(
        "section[class*='org-page-details-module__card-spacing'] dl dt",
        {
          timeout: 7000
        }
      )
    ])

    const topCardTpl = `
div[class*="org-top-card__primary"]
  h1{company_name}`

    const detailsTpl = `
section[class*="org-page-details"]
  p{overview}
  dl
    dd
      a[website_url=href]
    dd{industry}
    dd{company_size}
    dd{headquarters}
    dd{founded}
    dd{specialties}`

    const [companyNameData, detailsData] = await Promise.all([
      harvestPage(
        this.page,
        topCardTpl,
        'div[class*="org-top-card__primary"]',
        {
          dataOnly: true,
          inject: true
        }
      ),
      harvestPage(this.page, detailsTpl, 'section[class*="org-page-details"]', {
        dataOnly: true,
        inject: true
      })
    ])

    detailsData.website_url = detailsData.website_url
      ? detailsData.website_url.replace(
          new URL(detailsData.website_url).search,
          ''
        )
      : null

    return { ...companyNameData, ...detailsData }
  }

  async #loginCheck(): Promise<boolean> {
    const loc = this.page.getByRole('button', { name: /sign in/i }).first()

    if (await loc.isVisible()) {
      await this.login()

      return false
    }

    return true
  }

  async #fetchPost(el: Locator): Promise<Post | null> {
    const showMore = el.getByRole('button', {
      name: /more/i
    })

    if (await showMore.isVisible()) {
      await showMore.click()
    }

    const [unique_id, content, actor, time_ago, images] = await Promise.all([
      el.getAttribute('data-urn'),
      this.runLocatorIfVisible(
        el.locator('.update-components-text').first(),
        async (loc: Locator) => {
          return await loc.evaluate(ele => {
            ele
              .querySelectorAll("script,style,link,svg,[src^='data:image/']")
              .forEach(it => {
                it.remove()
              })

            return (
              ele.textContent
                ?.trim()
                // Replace repeated newlines (with optional surrounding spaces) with a single newline
                .replace(/(\s*\n\s*){2,}/g, '\n')
                // Normalize remaining whitespace (optional: remove extra spaces between words)
                .replace(/[ \t]+/g, ' ')
                .toLowerCase()
            )
          })
        }
      ),
      this.runLocatorIfVisible(
        el.locator('.update-components-actor__container').first(),
        async (loc: Locator) => {
          return await loc.evaluate(ele => {
            // @ts-expect-error this is loaded in runtime
            return harvest(
              `
div
  a[link=profile_url]
    span
      span
        span
          span{name}
    span
      span{description}`,
              ele,
              {
                dataOnly: true,
                inject: true
              }
            )
          })
        }
      ),
      this.runLocatorIfVisible(
        el
          .locator(
            '.update-components-actor__sub-description > span:first-child'
          )
          .first(),
        async (loc: Locator) => {
          return await loc.evaluate(ele => {
            return ele.textContent?.trim().split(' ')?.[0]
          })
        }
      ),
      el.locator('.update-components-image img').evaluateAll(items => {
        return items
          .map(it => it.getAttribute('src'))
          .filter(it => it && !it.startsWith('data'))
      })
    ])

    if (actor) {
      // remove query params
      actor.profile_url = actor?.profile_url
        ? actor.profile_url.replace(new URL(actor.profile_url).search, '')
        : null
    }

    if (!content) {
      return null
    }

    return {
      unique_id,
      actor,
      content,
      time_ago,
      images
    }
  }
}
