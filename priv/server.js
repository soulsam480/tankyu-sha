// import fastify from 'fastify'
// import { chromium } from 'playwright-extra'
// import StealthPlugin from 'puppeteer-extra-plugin-stealth'
// import dotenv from 'dotenv'
// import { Linkedin } from './modules/linkedin.mjs'
// import { Search } from './modules/search.mjs'
// import fs from 'node:fs/promises'
// import path from 'node:path'
// import { News } from './modules/news.mjs'
//
// dotenv.config()
//
// chromium.use(StealthPlugin())
//
// const STORAGE_STATE_PATH = path.join(process.cwd(), 'storage_state.json')
//
// const SERVICE_TO_CTOR = { LinkedIn: Linkedin, News: News, Search: Search }
//
// /** @type {import("playwright").ChromiumBrowser | null} */
// let browser = null
//
// const app = fastify({ logger: true })
//
// app.get('/', (_, reply) => {
//   reply.send('Hello')
// })
//
// app.get('/api/health', (_, reply) => {
//   reply.send({ status: 'ok' })
// })
//
// app.post('/api/process', async (req, reply) => {
//   let close
//
//   try {
//     const { url, kind, ...params } = req.body
//
//     if (!url) {
//       reply.code(400).send({ error: { type: 'NO_URL' } })
//       return
//     }
//
//     browser = await chromium.launch({
//       headless: true,
//       executablePath: '/Applications/Chromium.app/Contents/MacOS/Chromium',
//       args: [
//         '--disable-blink-features=AutomationControlled',
//         '--disable-features=IsolateOrigins,site-per-process',
//         '--disable-site-isolation-trials',
//         '--disable-web-security'
//       ]
//     })
//
//     let context
//
//     try {
//       const storageState = await fs.readFile(STORAGE_STATE_PATH, 'utf-8')
//
//       context = await browser.newContext({
//         bypassCSP: true,
//         storageState: JSON.parse(storageState)
//       })
//     } catch (_) {
//       context = await browser.newContext({
//         bypassCSP: true
//       })
//     }
//
//     context.route('**/*', (route, request) => {
//       const url = request.url()
//
//       // NOTE: we're responding with dummy css so client
//       // rendered apps continue to work when stylesheets are
//       // injectsed dynamically to the page with link tags
//       if (request.resourceType() === 'stylesheet') {
//         return route.fulfill({
//           status: 200,
//           contentType: 'text/css',
//           body: '/* dummy css */\nbody { margin: 0px }'
//         })
//       }
//
//       if (
//         ['image', 'font', 'media'].includes(request.resourceType()) ||
//         url.includes('googletagmanager') ||
//         url.includes('doubleclick')
//       ) {
//         route.abort()
//       } else {
//         route.continue()
//       }
//     })
//
//     close = async () => {
//       try {
//         const storageState = await context.storageState()
//
//         await fs.writeFile(
//           STORAGE_STATE_PATH,
//           JSON.stringify(storageState, null, 2)
//         )
//       } catch (_) {}
//
//       if (!browser?.isConnected()) {
//         return
//       }
//
//       await context?.close()
//       await browser?.close()
//     }
//
//     if (!kind) {
//       await close()
//       reply.send({ data: [] })
//       return
//     }
//
//     const Ctor = SERVICE_TO_CTOR[kind]
//
//     if (!Ctor) {
//       await close()
//       reply.code(400).send({ error: { type: 'UNKNOWN_SOURCE' } })
//       return
//     }
//
//     /**  @type {import("./modules/source.mjs").Source} */
//     const source = new Ctor(context, params)
//
//     await source.init()
//
//     const response = await source.process(String(url))
//
//     reply.send(response)
//   } catch (e) {
//     reply.code(500).send({
//       error: {
//         type: 'PROCESS_ERROR',
//         details:
//           typeof e?.toString === 'function' ? e.toString() : JSON.stringify(e)
//       }
//     })
//   } finally {
//     close?.()
//   }
// })
//
// // Run the server!
// const start = async () => {
//   try {
//     await app.listen({ port: 3000 })
//   } catch (err) {
//     app.log.error(err)
//     process.exit(1)
//   }
// }
//
// start()
