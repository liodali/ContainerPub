#!/bin/bash

skip="${1:-no-skip}"

if [ "$skip" != "--skip" ]; then
rm -rf cloudflare_deploy_site/public
rm -rf build/jaspr

mkdir -p cloudflare_deploy_site/public/build

jaspr build --sitemap-exclude -O 3 --verbose 

cp -r build/jaspr cloudflare_deploy_site/public/build
fi
cd cloudflare_deploy_site
bun install
bunx wrangler pages deploy public/build/jaspr
rm -rf node_modules
echo "Deployed successfully"

