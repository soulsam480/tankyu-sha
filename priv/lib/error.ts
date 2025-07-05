interface RunnerErrorData {
  type: string
  details: string | undefined
}

export class RunnerError extends Error {
  /** @type {RunnerErrorData} */
  #error: RunnerErrorData

  constructor(error: RunnerErrorData) {
    super(JSON.stringify(error))
    this.#error = error
  }
}
