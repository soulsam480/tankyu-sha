import { Source } from './source.mjs'
import { harvestPageAll } from 'js-harvester/playwright.js'

export class Harvest extends Source {
  get type() {
    return 'harvest'
  }

  get requiresLogin() {
    return false
  }

  /**
   * @param {string} url process provided url
   */
  async process(url) {
    await this.page.goto(url, { waitUntil: 'load' })

    const {
      /** @type {string} */
      selector = '',
      /** @type {string} */
      template = ''
    } = this.params

    await this.page.waitForSelector(selector)

    const data = await harvestPageAll(this.page, template, selector, {
      inject: true,
      dataOnly: true
    })

    return JSON.stringify({ data })
  }
}
