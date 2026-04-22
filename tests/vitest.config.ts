import { defineConfig } from "vitest/config";

export default defineConfig({
  server: {
    fs: {
      allow: ["/app", "."],
    },
  },
  test: {
    environment: "happy-dom",
    include: ["unit/**/*.spec.ts"],
    globals: true,
  },
});
