import { Source } from './source.mjs'
// @ts-ignore ignore
import { harvestPage } from 'js-harvester/playwright.js'
import { LinkedInUrlInfo } from './linkedin-url-info.mjs'
import { RunnerError } from '../lib/error.mjs'

/**
 * @typedef {Object} Post
 * @property {string} content - post content
 * @property {number} [id] - post id
 */

export class Linkedin extends Source {
  get requiresLogin() {
    return false
  }

  get type() {
    return 'linked_in'
  }

  get loginUrl() {
    return 'https://www.linkedin.com/uas/login'
  }

  async login() {
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

  /**
   * @param {string} url process provided url
   */
  async process(url) {
    const urlInfo = new LinkedInUrlInfo(url)

    if (urlInfo.isUnknown || !urlInfo.feedUrl) {
      throw new RunnerError({
        type: 'UNKNOWN_LINKEDIN_KIND',
        details: 'Unknown LinkedIn kind or feed URL is not available.'
      })
    }

    await this.page.goto(urlInfo.feedUrl)

    await this.#loginCheck()

    const promises = []

    promises.push(this.#getCompanyAboutInfo(urlInfo))

    promises.push(this.#getPosts(urlInfo))

    const [companyInfo, posts] = await Promise.all(promises)

    return JSON.stringify({
      data: {
        posts,
        companyInfo
      }
    })
  }

  /** @param {LinkedInUrlInfo} urlInfo */
  async #getPosts(urlInfo) {
    const page = await this.page.context().newPage()

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

    const rows = await page.locator('[role="article"]').all()

    const posts = await Promise.all(
      rows.map(async (el, index) => {
        const showMore = el.getByRole('button', {
          name: /more/i
        })

        if (await showMore.isVisible()) {
          await showMore.click()
        }

        const content = await el
          .locator('div[class*="update-components-text"]')
          .textContent()

        return {
          id: index + 1,
          content
        }
      })
    )

    return posts
  }

  /**
   * @param {LinkedInUrlInfo} urlInfo
   */
  async #getCompanyAboutInfo(urlInfo) {
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
        { timeout: 7000 }
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

    return { ...companyNameData, ...detailsData }
  }

  async #loginCheck() {
    const loc = this.page.getByRole('button', { name: /sign in/i }).first()

    // await loc.waitFor({ state: 'visible' })

    if (await loc.isVisible()) {
      await this.login()

      return true
    }

    return false
  }
}
