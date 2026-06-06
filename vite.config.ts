import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  root: 'frontend',
  server: {
    port: 5173,
    proxy: {
      '/import': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
      '/accounts': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
      '/categories': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
      '/api/auth': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
});
