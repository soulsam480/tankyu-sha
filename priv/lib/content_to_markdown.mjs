/**
 * @typedef {Object} Contentable
 * @property {string} content - content
 * @property {string} time_ago - time ago
 * @property {string[]} images - images
 * @property {string} actor_name - actor
 * @property {string} actor_description - actor
 * @property {string} actor_profile_url - actor
 * @property {string} unique_id - unique id
 */

/**
 * @param {number} index
 * @param {Contentable} content
 */
export function contentToMarkdown(index, content) {
  return `# Post ${index} with unique id ${content.unique_id}

## From Actor
- name: ${content.actor_name}
- description: ${content.actor_description}
- profile url: ${content.actor_profile_url}

## Post content below
${content.content}

was posted ${content.time_ago} back with attached images: ${content.images.length > 0 ? content.images.map(it => `- ${it}`).join('\n') : 'no images'}
`
}
