import { defineConfig } from 'vite'
import viteReact from '@vitejs/plugin-react-swc'
import tailwindcss from '@tailwindcss/vite'

import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import { resolve } from 'node:path'

// https://vitejs.dev/config/
export default defineConfig({
  root: 'app',
  plugins: [
    TanStackRouterVite({
      autoCodeSplitting: true,
      routesDirectory: 'app/src/routes',
      generatedRouteTree: 'app/src/routeTree.gen.ts'
    }),
    viteReact(),
    tailwindcss()
  ],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080'
      }
    }
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src')
    }
  }
})
