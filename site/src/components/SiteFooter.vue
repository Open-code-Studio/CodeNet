<script setup>
import { REPO, ISSUES, RELEASES, UPSTREAM, WORKFLOW } from '../data/downloads.js'

const links = [
  { text: '仓库', href: REPO },
  { text: '发布', href: RELEASES },
  { text: '问题反馈', href: ISSUES },
  { text: '构建工作流', href: WORKFLOW }
]
</script>

<template>
  <footer class="footer">
    <div class="shell" style="display: flex; flex-wrap: wrap; gap: 18px; justify-content: space-between; align-items: center; width: 100%">
      <span>
        CODE.NET — 继承上游 .NET Runtime 的 MIT 许可 · 基于
        <a class="accent" :href="UPSTREAM" target="_blank" rel="noreferrer">dotnet/runtime</a> 构建
      </span>
      <span class="footer-links">
        <a v-for="link in links" :key="link.href" :href="link.href" target="_blank" rel="noreferrer">
          {{ link.text }} ↗
        </a>
      </span>
    </div>
  </footer>
</template>