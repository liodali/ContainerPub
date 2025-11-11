<script setup lang="ts">
type FeatureKey = 'dart' | 'containers' | 'webhooks'

const props = defineProps<{ selected: FeatureKey }>()
const emit = defineEmits<{ (e: 'select', key: FeatureKey): void }>()

const items: { key: FeatureKey; label: string; badge?: string }[] = [
  { key: 'dart', label: 'Dart Functions', badge: 'Now' },
  { key: 'containers', label: 'Container Deploy', badge: 'Next' },
  { key: 'webhooks', label: 'Webhook Cache', badge: 'Soon' }
]

const onSelect = (key: FeatureKey) => emit('select', key)
</script>

<template>
  <nav class="mt-6">
    <ul class="flex justify-center gap-2">
      <li v-for="item in items" :key="item.key">
        <button
          class="inline-flex items-center gap-2 px-3 py-2 rounded border"
          :class="props.selected === item.key ? 'border-indigo-500 text-indigo-400' : 'border-transparent hover:border-neutral-300'"
          @click="onSelect(item.key)"
        >
          <span>{{ item.label }}</span>
          <span v-if="item.badge" class="text-xs px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-400">{{ item.badge }}</span>
        </button>
      </li>
    </ul>
  </nav>
</template>

<style scoped></style>