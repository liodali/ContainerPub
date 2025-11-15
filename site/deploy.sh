bun install 
bun run build
cd containerpub-site
bun install 
bun run deploy
rm -rf node_modules
cd ..
rm -rf node_modules
echo "Deployed successfully"