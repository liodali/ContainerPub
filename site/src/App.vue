<script setup lang="ts">
import { ref } from 'vue'
import FeatureNav from './components/FeatureNav.vue'
import DartFunctions from './components/DartFunctions.vue'
import ContainerDeploy from './components/ContainerDeploy.vue'
import WebhookCache from './components/WebhookCache.vue'
import HeroSection from './components/HeroSection.vue'
import FeaturesGrid from './components/FeaturesGrid.vue'
import HowItWorks from './components/HowItWorks.vue'

type FeatureKey = 'dart' | 'containers' | 'webhooks'
const selected = ref<FeatureKey>('dart')

const onSelect = (key: FeatureKey) => {
  selected.value = key
}

const logoMark = new URL('./assets/containerpub-mark.svg', import.meta.url).href
</script>

<template>
  <header class="max-w-5xl mx-auto px-4 pt-10 text-center">
    <img :src="logoMark" alt="ContainerPub" class="block h-24 mx-auto" />
    <div>
      <h1 class="text-3xl font-semibold mt-0">ContainerPub</h1>
      <p class="mt-1 text-muted-foreground">Cloud service for Dart Functions, Containers, and Webhooks</p>
    </div>
    <p class="mt-6 text-lg text-muted-foreground">Build serverless Dart functions and deploy containers with a simple
      workflow. Webhook triggers and caching are coming soon.</p>
  </header>

  <section class="max-w-5xl mx-auto px-4 mt-8">
    <HeroSection @select="onSelect" />
  </section>

  <section class="max-w-5xl mx-auto px-4 mt-8">
    <FeatureNav :selected="selected" @select="onSelect" />
  </section>

  <main class="max-w-5xl mx-auto px-4 mt-8">
    <FeaturesGrid @select="onSelect" />
    <section v-if="selected === 'dart'" class="mt-12">
      <DartFunctions />
    </section>
    <section v-else-if="selected === 'containers'">
      <ContainerDeploy />
    </section>
    <section v-else>
      <WebhookCache />
    </section>

    <HowItWorks />
  </main>

  <footer class="max-w-5xl mx-auto px-4 mt-10 text-center text-muted-foreground">
    © {{ new Date().getFullYear() }} ContainerPub
  </footer>
</template>

<style scoped>
.text-muted-foreground {
  color: #888;
}
</style>
