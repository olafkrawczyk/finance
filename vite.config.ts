import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const spaBypass = (req: { headers: { accept?: string } }) => {
  if (req.headers.accept?.includes('text/html')) return '/index.html';
};

export default defineConfig({
  plugins: [react()],
  root: 'frontend',
  server: {
    port: 5173,
    proxy: {
      '/import': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/api/migration': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/accounts': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/categories': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/api/auth': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/transactions': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/opening-balance': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/insights': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
      '/assets': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: spaBypass,
      },
    },
  },
});

