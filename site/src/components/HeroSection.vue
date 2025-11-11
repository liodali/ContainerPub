<script setup lang="ts">
type FeatureKey = 'dart' | 'containers' | 'webhooks'
const emit = defineEmits<{ (e: 'select', key: FeatureKey): void }>()
const pick = (key: FeatureKey) => emit('select', key)
</script>

<template>
  <section class="relative overflow-hidden">
    <div class="absolute inset-0 -z-10 opacity-20" aria-hidden="true">
      <div class="h-64 bg-gradient-to-r from-indigo-500/40 via-sky-500/30 to-purple-500/40 blur-3xl"></div>
    </div>
    <div class="text-center">
      <h1 class="text-4xl md:text-5xl font-semibold tracking-tight">Build, Deploy, and Trigger with ContainerPub</h1>
      <p class="mt-3 text-lg text-muted-foreground">
        Serverless Dart functions, container deployments, and reliable webhook triggers—all in one cloud.
      </p>

      <div class="mt-6 flex items-center justify-center gap-3">
        <button class="px-4 py-2 rounded bg-indigo-600 text-white hover:bg-indigo-500" @click="pick('dart')">
          Start with Dart Functions
        </button>
        <button class="px-4 py-2 rounded border border-neutral-300 hover:border-neutral-400" @click="pick('containers')">
          Explore Container Deploy
        </button>
      </div>

      <div class="mt-8 mx-auto max-w-3xl text-left rounded border border-neutral-700/40 p-4">
        <p class="text-sm text-muted-foreground">Example Dart function:</p>
        <pre class="mt-2 overflow-auto rounded bg-neutral-900 p-4 text-sm"><code>// hello.dart
import 'dart:io';

void main() {
  stdout.writeln('Hello from ContainerPub Dart function');
}
</code></pre>
      </div>
    </div>
  </section>
</template>

<style scoped></style>