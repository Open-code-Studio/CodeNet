<script setup>
import { asset, sdkDownloads, runtimeDownloads, RELEASES, RELEASE_TAG } from '../data/downloads.js'
</script>

<template>
  <section id="download" class="section">
    <div class="shell">
      <div class="section-head">
        <div>
          <div class="label">Downloads</div>
          <h2 class="section-title">获取 Code.NET</h2>
        </div>
        <a class="label" :href="RELEASES" target="_blank" rel="noreferrer">全部发布 ↗</a>
      </div>

      <p class="lede" style="margin-bottom: 34px">
        从 Releases 下载对应平台的预构建运行时 / SDK，当前发布标签为
        <span class="mono">{{ RELEASE_TAG }}</span>。
      </p>

      <div class="group-title">完整 SDK 布局 · 推荐 macOS 使用</div>
      <div class="grid-downloads">
        <article v-for="item in sdkDownloads" :key="item.id" class="card">
          <div class="card-top">
            <span class="card-platform">{{ item.platform }} · {{ item.arch }}</span>
            <span v-if="item.recommended" class="tag tag-rec">推荐</span>
            <span v-else class="tag tag-runtime">SDK 布局</span>
          </div>
          <div class="card-asset">{{ item.asset }}</div>
          <p class="card-note">{{ item.note }}</p>
          <a class="card-link" :href="asset(item.asset)">
            下载 <span aria-hidden="true">↓</span>
          </a>
        </article>
      </div>

      <div class="group-title" style="margin-top: 44px">Runtime 包 · 需并入既有 SDK</div>
      <div class="grid-downloads">
        <article v-for="item in runtimeDownloads" :key="item.id" class="card">
          <div class="card-top">
            <span class="card-platform">{{ item.platform }} · {{ item.arch }}</span>
            <span class="tag tag-runtime">Runtime</span>
          </div>
          <div class="card-asset">{{ item.asset }}</div>
          <p class="card-note">{{ item.note }}</p>
          <a class="card-link" :href="asset(item.asset)">
            下载 <span aria-hidden="true">↓</span>
          </a>
        </article>
      </div>

      <div class="notice">
        <strong>认准 -fixed 后缀。</strong>
        同一发布标签下还存在 CI 自动上传的同名运行时包
        <span class="mono">dotnet-codenet-osx-arm64.tar.gz</span>。它是平铺的 CoreCLR 与共享框架文件，
        不含 <span class="mono">dotnet11x64/</span> SDK 布局，不能直接当 SDK 使用。
      </div>
    </div>
  </section>
</template>