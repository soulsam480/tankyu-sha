import { resolve } from "node:path";
import tailwindcss from "@tailwindcss/vite";
import { tanstackRouter } from "@tanstack/router-plugin/vite";
import viteReact from "@vitejs/plugin-react-swc";
import { defineConfig } from "vite";

import Icons from "unplugin-icons/vite";

// https://vitejs.dev/config/
export default defineConfig({
  root: "app",
  plugins: [
    Icons({ compiler: "jsx", jsx: "react" }),
    tanstackRouter({
      autoCodeSplitting: true,
      routesDirectory: "app/src/routes",
      generatedRouteTree: "app/src/routeTree.gen.ts",
    }),
    viteReact(),
    tailwindcss(),
  ],
  server: {
    proxy: {
      "/api": {
        target: "http://localhost:8080",
      },
    },
  },
  resolve: {
    alias: {
      "@": resolve(__dirname, "app/src"),
    },
  },
});
