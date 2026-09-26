import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 站点部署在 https://open-code-studio.github.io/CodeNet/ 子路径下，
// base 必须与仓库名一致，否则静态资源会 404。
export default defineConfig({
  base: '/CodeNet/',
  plugins: [vue()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    emptyOutDir: true
  }
})