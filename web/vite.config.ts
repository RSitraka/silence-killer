import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { VitePWA } from 'vite-plugin-pwa';

// Application web installable (PWA) : après la première visite, tout
// (code, police, sons) est mis en cache et le jeu fonctionne hors ligne.
export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['icons/*.png', 'icons/favicon.svg'],
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,ttf,wav,webmanifest}'],
      },
      manifest: {
        name: "Clin d'Œil Assassin",
        short_name: "Clin d'Œil",
        description: 'Jeu de société en groupe, sur un seul téléphone, sans parler.',
        lang: 'fr',
        start_url: '/',
        display: 'standalone',
        orientation: 'portrait',
        background_color: '#FFF6EC',
        theme_color: '#FFE8F1',
        icons: [
          { src: 'icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: 'icons/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
    }),
  ],
  test: {
    environment: 'node',
  },
});
