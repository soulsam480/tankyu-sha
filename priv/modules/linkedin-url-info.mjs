const PROFILE_REGEXP = /^\/(?:in|pub)\/(?<handle>[\w\-À-ÿ%]+)\/?/i

const COMPANY_REGEXP =
  /^\/(?:company|school)\/(?<handle>[A-Za-z0-9\-À-ÿ\.]+)\/?/i

const POST_SLUG_REGEXP =
  /^\/posts\/(?<slug>[\w\-À-ÿ%]+)-activity-(?<activityId>\d+)(?:-\w+)?\/?/i

const FEED_UPDATE_REGEXP =
  /^\/feed\/update\/urn:li:activity:(?<activityId>\d+)\/?/i

const GENERIC_ACTIVITY_REGEXP = /activity[:\-](?<activityId>\d{10,})/i

export class LinkedInUrlInfo {
  /** @type {URL} */
  #urlObject
  /** @type {string} */
  #pageKind
  /** @type {string | null} */
  #handle = null

  /**
   * @param {string} urlString
   */
  constructor(urlString) {
    this.#urlObject = new URL(urlString)
    this.#pageKind = this.#determinePageKind()
    this.#handle = this.#extractHandle()
  }

  #determinePageKind() {
    if (PROFILE_REGEXP.test(this.#urlObject.pathname)) {
      return 'profile'
    }

    if (COMPANY_REGEXP.test(this.#urlObject.pathname)) {
      return 'company'
    }

    if (
      POST_SLUG_REGEXP.test(this.#urlObject.pathname) ||
      FEED_UPDATE_REGEXP.test(this.#urlObject.pathname) ||
      GENERIC_ACTIVITY_REGEXP.test(this.#urlObject.pathname)
    ) {
      return 'post'
    }

    return 'unknown'
  }

  #extractHandle() {
    let match

    if (this.isProfile) {
      match = this.#urlObject.pathname.match(PROFILE_REGEXP)
    } else if (this.isCompany) {
      match = this.#urlObject.pathname.match(COMPANY_REGEXP)
    }

    return match?.groups?.handle || null
  }

  get originalUrl() {
    return this.#urlObject.href
  }

  get hostname() {
    return this.#urlObject.hostname
  }

  get pathname() {
    return this.#urlObject.pathname
  }

  get pageKind() {
    return this.#pageKind
  }

  get isProfile() {
    return this.#pageKind === 'profile'
  }

  get isCompany() {
    return this.#pageKind === 'company'
  }

  get isUnknown() {
    return this.#pageKind === 'unknown'
  }

  get isStandalonePost() {
    return this.#pageKind === 'post'
  }

  get handle() {
    return this.#handle
  }

  get feedUrl() {
    if (this.isProfile && this.handle) {
      return `https://${this.hostname}/in/${this.handle}/recent-activity/all`
    }

    if (this.isCompany && this.handle) {
      return `https://${this.hostname}/company/${this.handle}/posts/?feedView=all`
    }

    return null
  }

  get companyAboutUrl() {
    if (this.isCompany && this.handle) {
      return `https://${this.hostname}/company/${this.handle}/about/`
    }

    return null
  }
}
