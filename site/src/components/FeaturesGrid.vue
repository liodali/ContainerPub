<script setup lang="ts">
type FeatureKey = 'dart' | 'containers' | 'webhooks'
const emit = defineEmits<{ (e: 'select', key: FeatureKey): void }>()
const pick = (key: FeatureKey) => emit('select', key)

const items: { key: FeatureKey; title: string; desc: string; badge: string }[] = [
  { key: 'dart', title: 'Dart Functions', desc: 'Serverless Dart with instant endpoints and auto scaling.', badge: 'Now' },
  { key: 'containers', title: 'Container Deploy', desc: 'OCI containers with simple rollouts and health checks.', badge: 'Next' },
  { key: 'webhooks', title: 'Webhook Triggers + Cache', desc: 'Reliable delivery with caching, replay, and TTLs.', badge: 'Soon' },
]
</script>

<template>
  <section class="mt-10">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <article v-for="item in items" :key="item.key" class="rounded border p-4 bg-neutral-900/30">
        <div class="flex items-center gap-2">
          <h3 class="text-lg font-medium">{{ item.title }}</h3>
          <span class="text-xs px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-400">{{ item.badge }}</span>
        </div>
        <p class="mt-2 text-sm text-muted-foreground">{{ item.desc }}</p>
        <button class="mt-3 text-indigo-500 hover:underline" @click="pick(item.key)">Learn more</button>
      </article>
    </div>
  </section>
</template>

<style scoped></style>