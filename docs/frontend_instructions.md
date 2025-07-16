# Frontend instructions for Tankyu-Sha

## Source

- [app](../app)

## Tech used

- React as the UI rendering library
- Tanstack router for routing
- Radix UI for styling and UI components
- Unplugin icons for icons (Carbon Icons collection)

## Workflow

When asked to work on UI, follow the following rules

- First get clear understanding of the requirement, ask as many questions before
  going ahead
- Always try to keep components granular and small.
- Simple rule is each component per one file
- When seeing repeatitive patterns from feedback, add it to your memory.
- Make it a habit to remember a lot of patterns from feedback
- Before pulling a library component from Radix UI, Always and always pull the
  documentation first using context 7
- First read how the component works, what are the props it takes, what are the
  examples and then use it
- Always make it a habit to look for docs for a library before assuming how it
  works
- Make sure to follow a consistent theme across all components.
- To complete the feedback loop after making any change to UI, make sure to take
  screenshots using browser mcp
- so make a change, fix lint issues and then take a screenshot of the app and
  the route being worked on
- the app is running at http://localhost:3000, understand if the changes are
  expected or not and keep iterating.
- When you need to work with icons, make sure to check if any icon exists or not
  by querying this url -> https://icones.js.org/collection/carbon?s=pap, if it
  doesn't exist, try with some other keyword and repeat. here `s` is the icon
  query param
- Try to use relevant icons
