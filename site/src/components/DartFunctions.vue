<script setup lang="ts">
// No external dependencies; simple informational and CTA section for Dart Functions
</script>

<template>
  <section class="text-left">
    <h2 class="text-2xl font-semibold">Dart Cloud Functions</h2>
    <p class="mt-2 text-muted-foreground">
      Author, deploy, and run serverless Dart functions on ContainerPub. Start with
      lightweight endpoints and scale seamlessly.
    </p>

    <div class="mt-4 rounded border border-indigo-200/40 p-4">
      <h3 class="text-lg font-medium">Quick Start</h3>
      <ol class="list-decimal ml-6 mt-2 space-y-1">
        <li>Create a Dart function project locally.</li>
        <li>Connect your repo to ContainerPub.</li>
        <li>Deploy and get an instant HTTPS endpoint.</li>
      </ol>

      <div class="mt-3 flex items-center gap-3">
        <button class="px-3 py-2 rounded border border-neutral-300 opacity-60 cursor-not-allowed" disabled title="Backend integration pending">Deploy Dart Function</button>
        <a class="text-indigo-500" href="#" aria-disabled="true" title="Docs coming soon">Docs</a>
      </div>
      <p class="mt-2 text-sm text-muted-foreground">Initial release ships Dart Functions first.</p>
    </div>
  </section>
</template>

<style scoped></style>