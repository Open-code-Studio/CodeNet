<script setup>
import { REPO } from '../data/downloads.js'

const links = [
  { href: '#download', text: '下载' },
  { href: '#why', text: '修复内容' },
  { href: '#usage', text: '使用' },
  { href: '#build', text: '从源码构建' }
]
</script>

<template>
  <header class="nav">
    <div class="shell nav-inner">
      <a class="brand" href="#top">
        <span class="brand-dot" aria-hidden="true"></span>
        <span>CODE.NET</span>
      </a>
      <nav class="nav-links">
        <a v-for="link in links" :key="link.href" :href="link.href">{{ link.text }}</a>
      </nav>
      <a class="nav-gh" :href="REPO" target="_blank" rel="noreferrer">GITHUB ↗</a>
    </div>
  </header>
</template>