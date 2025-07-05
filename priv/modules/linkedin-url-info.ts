const PROFILE_REGEXP = /^\/(?:in|pub)\/(?<handle>[\w\-À-ÿ%]+)\/?/i;

const COMPANY_REGEXP =
  /^\/(?:company|school)\/(?<handle>[A-Za-z0-9\-À-ÿ\.]+)\/?/i;

const POST_SLUG_REGEXP =
  /^\/posts\/(?<slug>[\w\-À-ÿ%]+)-activity-(?<activityId>\d+)(?:-\w+)?\/?/i;

const FEED_UPDATE_REGEXP =
  /^\/feed\/update\/urn:li:activity:(?<activityId>\d+)\/?/i;

const GENERIC_ACTIVITY_REGEXP = /activity[:\-](?<activityId>\d{10,})/i;

export class LinkedInUrlInfo {
  #urlObject: URL;
  #pageKind: string;
  #handle: string | null = null;

  constructor(urlString: string) {
    this.#urlObject = new URL(urlString);
    this.#pageKind = this.#determinePageKind();
    this.#handle = this.#extractHandle();
  }

  #determinePageKind(): string {
    if (PROFILE_REGEXP.test(this.#urlObject.pathname)) {
      return "profile";
    }

    if (COMPANY_REGEXP.test(this.#urlObject.pathname)) {
      return "company";
    }

    if (
      POST_SLUG_REGEXP.test(this.#urlObject.pathname) ||
      FEED_UPDATE_REGEXP.test(this.#urlObject.pathname) ||
      GENERIC_ACTIVITY_REGEXP.test(this.#urlObject.pathname)
    ) {
      return "post";
    }

    return "unknown";
  }

  #extractHandle(): string | null {
    let match: RegExpMatchArray | null;

    if (this.isProfile) {
      match = this.#urlObject.pathname.match(PROFILE_REGEXP);
    } else if (this.isCompany) {
      match = this.#urlObject.pathname.match(COMPANY_REGEXP);
    } else {
      match = null;
    }

    return match?.groups?.handle || null;
  }

  get originalUrl(): string {
    return this.#urlObject.href;
  }

  get hostname(): string {
    return this.#urlObject.hostname;
  }

  get pathname(): string {
    return this.#urlObject.pathname;
  }

  get pageKind(): string {
    return this.#pageKind;
  }

  get isProfile(): boolean {
    return this.#pageKind === "profile";
  }

  get isCompany(): boolean {
    return this.#pageKind === "company";
  }

  get isUnknown(): boolean {
    return this.#pageKind === "unknown";
  }

  get isStandalonePost(): boolean {
    return this.#pageKind === "post";
  }

  get handle(): string | null {
    return this.#handle;
  }

  get feedUrl(): string | null {
    if (this.isProfile && this.handle) {
      return `https://${this.hostname}/in/${this.handle}/recent-activity/all`;
    }

    if (this.isCompany && this.handle) {
      return `https://${this.hostname}/company/${this.handle}/posts/?feedView=all`;
    }

    return null;
  }

  get companyAboutUrl(): string | null {
    if (this.isCompany && this.handle) {
      return `https://${this.hostname}/company/${this.handle}/about/`;
    }

    return null;
  }
}
