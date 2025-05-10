import { chromium } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import dotenv from 'dotenv'
import { Linkedin } from './modules/linkedin.mjs'
import { parseArgs } from 'node:util'
import { Search } from './modules/search.mjs'

dotenv.config()

chromium.use(StealthPlugin())

const SOURCE_TO_CTOR = {
  LinkedIn: Linkedin,
  Search: Search
}

async function main() {
  try {
    const { values } = parseArgs({
      strict: false,
      options: {
        url: {
          type: 'string',
          default: ''
        },
        kind: {
          type: 'string'
        },
        term: {
          type: 'string',
          default: ''
        },
        headless: {
          type: 'boolean',
          default: true
        }
      }
    })

    const { url, ...params } = values

    /** @type {keyof typeof SOURCE_TO_CTOR | null} */
    // @ts-expect-error
    const kind = values.kind || null

    if (!url) {
      console.log(JSON.stringify({ error: { type: 'NO_URL' } }))
      return
    }

    const browser = await chromium.launch({
      slowMo: 500,
      headless: Boolean(values.headless),
      executablePath: '/Applications/Chromium.app/Contents/MacOS/Chromium',
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-features=IsolateOrigins,site-per-process',
        '--disable-site-isolation-trials'
      ]
    })

    const context = await browser.newContext()

    const page = await context.newPage()

    // Set up human-like behaviors

    async function close() {
      await page.close()
      await context.close()
      await browser.close()
    }

    if (!kind) {
      // TODO: any kind process

      await close()
      console.log(JSON.stringify({ data: [] }))

      return
    }

    const Ctor = SOURCE_TO_CTOR[kind]

    if (!Ctor) {
      await close()
      console.log(JSON.stringify({ error: { type: 'UNKNOWN_SOURCE' } }))
      return
    }

    /**  @type {import("./modules/source.mjs").Source} */
    const source = new Ctor(page, params)

    await source.init()

    const response = await source.process(String(url))

    await close()

    console.log(response)
  } catch (e) {
    console.log(
      JSON.stringify({
        error: {
          type: 'PROCESS_ERROR',
          details: e
        }
      })
    )
  }
}

main()
