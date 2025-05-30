declare global {
  interface Window {
    isProbablyReaderable: (...args: amy[]) => boolean
    Readability: any
  }
}
