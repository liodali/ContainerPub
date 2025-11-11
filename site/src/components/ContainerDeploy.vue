<script setup lang="ts">
// Placeholder UI for container deployment flow
</script>

<template>
  <section class="text-left">
    <h2 class="text-2xl font-semibold">Container Deploy</h2>
    <p class="mt-2 text-muted-foreground">
      Build and deploy OCI containers with registry integration and automated rollouts.
    </p>

    <div class="mt-4 rounded border border-indigo-200/40 p-4">
      <h3 class="text-lg font-medium">Planned Flow</h3>
      <ul class="list-disc ml-6 mt-2 space-y-1">
        <li>Connect registry or Git source</li>
        <li>Configure service and environment</li>
        <li>Deploy with health checks and autoscaling</li>
      </ul>

      <div class="mt-3 flex items-center gap-3">
        <button class="px-3 py-2 rounded border border-neutral-300 opacity-60 cursor-not-allowed" disabled title="Feature ships after Dart Functions">Deploy Container</button>
        <span class="text-xs px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-400">Next</span>
      </div>
    </div>
  </section>
</template>

<style scoped></style>