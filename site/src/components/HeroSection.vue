<script setup>
import { RELEASE_TAG, REPO, RELEASES } from '../data/downloads.js'

const facts = [
  { k: '上游', v: 'dotnet/runtime' },
  { k: '发布标签', v: RELEASE_TAG },
  { k: '目标平台', v: 'macOS / Linux / Windows' },
  { k: '许可证', v: 'MIT' }
]
</script>

<template>
  <section id="top" class="shell hero">
    <div>
      <div class="label">Open-code-studio · dotnet runtime fork</div>
      <h1 class="hero-title">CODE<span class="tld">.NET</span></h1>
      <p class="hero-claim">让 .NET 在新版 macOS 上原厂即可用</p>
      <p class="lede">
        Code.NET 是 dotnet/runtime 的定制分支，针对新版 macOS（含 macOS 27 及后续版本）上
        .NET 运行时崩溃的问题做了修复。核心思路是把修复做进 SDK 本身：用 Code.NET SDK
        打包出的应用出厂即带修复运行时，发布后不再需要手工注入 dylib 或重签名。
      </p>
      <div class="hero-actions">
        <a class="btn btn-solid" href="#download">下载 <span aria-hidden="true">↓</span></a>
        <a class="btn" :href="REPO" target="_blank" rel="noreferrer">
          查看仓库 <span aria-hidden="true">↗</span>
        </a>
      </div>
    </div>

    <aside class="hero-panel">
      <div class="hero-panel-head">
        <span class="label">Build info</span>
        <a class="label" :href="RELEASES" target="_blank" rel="noreferrer">releases ↗</a>
      </div>
      <div class="hero-rows">
        <div v-for="fact in facts" :key="fact.k" class="hero-row">
          <span>{{ fact.k }}</span>
          <span>{{ fact.v }}</span>
        </div>
      </div>
    </aside>
  </section>
</template>