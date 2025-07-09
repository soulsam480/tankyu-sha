import fastify from 'fastify'
import { chromium } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import dotenv from 'dotenv'
import { Linkedin } from './modules/linkedin.ts'
import { Search } from './modules/search.ts'
import fs from 'node:fs/promises'
import path from 'node:path'
import { News } from './modules/news.ts'
import type { BrowserContext, ChromiumBrowser } from 'playwright'
import conf from './app_config.json' with { type: 'json' }

dotenv.config()

chromium.use(StealthPlugin())

const STORAGE_STATE_PATH = path.join(process.cwd(), 'storage_state.json')

const SERVICE_TO_CTOR = { LinkedIn: Linkedin, News: News, Search: Search }

let browser: ChromiumBrowser | null = null
let context: BrowserContext | null = null

const app = fastify({ logger: true })

app.get('/', (_, reply) => {
  reply.send('OK')
})

app.get('/api/close', (_, reply) => {
  reply.status(202).send({ ok: true })

  setTimeout(() => {
    context?.close()
    browser?.close()

    process.exit(0)
  }, 100)
})

interface QueryParams {
  use_system?: boolean
  url: string
  kind: keyof typeof SERVICE_TO_CTOR
  [x: string]: any
  headed?: boolean
}

app.get<{
  Querystring: QueryParams
}>('/api/process', async (req, reply) => {
  const { use_system = null, headed = false, url, kind, ...params } = req.query

  let close

  try {
    if (!url) {
      reply.code(400).send({ error: { type: 'NO_URL' } })
      return
    }

    browser ??= await chromium.launch({
      headless: !headed,
      executablePath:
        use_system || !conf.chrome_path ? undefined : conf.chrome_path,
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-features=IsolateOrigins,site-per-process',
        '--disable-site-isolation-trials',
        '--disable-web-security',
        '--disable-extensions',
        '--disable-gpu',
        '--disable-dev-shm-usage',
        '--disable-background-networking',
        '--disable-background-timer-throttling',
        '--disable-renderer-backgrounding',
        '--disable-backgrounding-occluded-windows',
        '--disable-plugins',
        '--no-sandbox',
        '--memory-pressure-off'
      ]
    })

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

    context.route('**/*', (route, request) => {
      const url = request.url()

      // NOTE: we're responding with dummy css so client
      // rendered apps continue to work when stylesheets are
      // injected dynamically to the page with link tags
      if (request.resourceType() === 'stylesheet') {
        return route.fulfill({
          status: 200,
          contentType: 'text/css',
          body: '/* dummy css */\nbody { margin: 0px }'
        })
      }

      if (
        ['image', 'font', 'media'].includes(request.resourceType()) ||
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
        const storageState = await context?.storageState()

        if (storageState) {
          await fs.writeFile(
            STORAGE_STATE_PATH,
            JSON.stringify(storageState, null, 2)
          )
        }
      } catch (_) {}
    }

    if (!kind) {
      await close()
      reply.send({ data: [] })
      return
    }

    const Ctor = SERVICE_TO_CTOR[kind]

    if (!Ctor) {
      await close()
      reply.code(400).send({ error: { type: 'UNKNOWN_SOURCE' } })
      return
    }

    const source = new Ctor(context, params)

    await source.init()

    const response = await source.process(String(url))

    reply.send(response)
  } catch (e) {
    reply.code(500).send({
      error: {
        type: 'PROCESS_ERROR',
        details:
          typeof e?.toString === 'function' ? e.toString() : JSON.stringify(e)
      }
    })
  } finally {
    close?.()
  }
})

// Run the server!
const start = async () => {
  try {
    await app.listen({ port: Number(process.env.BROWSER_SERVICE_PORT || 3000) })
  } catch (err) {
    app.log.error(err)
    process.exit(1)
  }
}

start()
