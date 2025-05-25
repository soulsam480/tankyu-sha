/**
 * @typedef {Object} RunnerErrorData
 * @property {string} type
 * @property {string|undefined} details
 */

export class RunnerError extends Error {
  /** @type {RunnerErrorData} */
  #error

  /**
   * @param {RunnerErrorData} error
   */
  constructor(error) {
    super(JSON.stringify(error))
    this.#error = error
  }
}
