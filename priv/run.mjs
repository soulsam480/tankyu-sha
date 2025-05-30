import { chromium } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import dotenv from 'dotenv'
import { Linkedin } from './modules/linkedin.mjs'
import { parseArgs } from 'node:util'
import { Search } from './modules/search.mjs'
import fs from 'node:fs/promises'
import path from 'node:path'
import { News } from './modules/news.mjs'

dotenv.config()

chromium.use(StealthPlugin())

const STORAGE_STATE_PATH = path.join(process.cwd(), 'storage_state.json')

const SERVICE_TO_CTOR = {
  LinkedIn: Linkedin,
  News: News,
  Search: Search
}

/** @type {import("playwright").ChromiumBrowser | null} */
let browser = null

async function main() {
  let close

  try {
    const { values } = parseArgs({
      strict: false,
      allowNegative: true,
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

    /** @type {keyof typeof SERVICE_TO_CTOR | null} */
    // @ts-expect-error
    const kind = values.kind || null

    if (!url) {
      console.log(JSON.stringify({ error: { type: 'NO_URL' } }))
      return
    }

    browser = await chromium.launch({
      headless: Boolean(values.headless),
      executablePath: '/Applications/Chromium.app/Contents/MacOS/Chromium',
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-features=IsolateOrigins,site-per-process',
        '--disable-site-isolation-trials',
        '--disable-web-security'
      ]
    })

    let context

    try {
      const storageState = await fs.readFile(STORAGE_STATE_PATH, 'utf-8')

      context = await browser.newContext({
        bypassCSP: true,
        storageState: JSON.parse(storageState)
      })
    } catch (_) {
      context = await browser.newContext({
        bypassCSP: true
      })
    }

    context.route('**/*', (route, req) => {
      const url = req.url()

      if (
        ['image', 'stylesheet', 'font'].includes(
          route.request().resourceType()
        ) ||
        url.includes('googletagmanager') ||
        url.includes('doubleclick')
      ) {
        route.abort()
      } else {
        route.continue()
      }
    })

    close = async () => {
      try {
        const storageState = await context.storageState()

        await fs.writeFile(
          STORAGE_STATE_PATH,
          JSON.stringify(storageState, null, 2)
        )
      } catch (_) {}

      await context?.close()
      await browser?.close()
    }

    if (!kind) {
      await close()
      console.log(JSON.stringify({ data: [] }))

      return
    }

    const Ctor = SERVICE_TO_CTOR[kind]

    if (!Ctor) {
      await close()
      console.log(JSON.stringify({ error: { type: 'UNKNOWN_SOURCE' } }))
      return
    }

    /**  @type {import("./modules/source.mjs").Source} */
    // @ts-expect-error ignore
    const source = new Ctor(context, params)

    await source.init()

    const response = await source.process(String(url))

    console.log(response)
  } catch (e) {
    console.log(
      JSON.stringify({
        error: {
          type: 'PROCESS_ERROR',
          details:
            typeof e?.toString === 'function' ? e.toString() : JSON.stringify(e)
        }
      })
    )
  } finally {
    close?.()
  }
}

main()

process.on('SIGINT', async () => {
  try {
    await browser?.close()
  } finally {
  }
})

process.on('exit', async () => {
  try {
    await browser?.close()
  } finally {
  }
})
