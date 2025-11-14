#!/bin/bash

rm -rf cloudflare_deploy_site/public
rm -rf build/jaspr

mkdir -p cloudflare_deploy_site/public/build

jaspr build --sitemap-exclude -O 3 --verbose 

cp -r build/jaspr cloudflare_deploy_site/public/build

cd cloudflare_deploy_site

bunx wrangler pages deploy public/build/jaspr