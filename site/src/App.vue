<script setup>
import SiteNav from './components/SiteNav.vue'
import HeroSection from './components/HeroSection.vue'
import StatsBand from './components/StatsBand.vue'
import DownloadSection from './components/DownloadSection.vue'
import FixSection from './components/FixSection.vue'
import UsageSection from './components/UsageSection.vue'
import BuildSection from './components/BuildSection.vue'
import SiteFooter from './components/SiteFooter.vue'
</script>

<template>
  <SiteNav />
  <main>
    <HeroSection />
    <StatsBand />
    <DownloadSection />
    <FixSection />
    <UsageSection />
    <BuildSection />
  </main>
  <SiteFooter />
</template>