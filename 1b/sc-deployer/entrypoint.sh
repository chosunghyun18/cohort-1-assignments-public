#!/bin/sh

set -e

echo "🚀 Starting smart contract deployment..."

# Wait for geth-init to complete prefunding
echo "⏳ Waiting for geth-init to complete prefunding..."
until [ -f "/shared/geth-init-complete" ]; do
  echo "Waiting for geth-init-complete file..."
  sleep 1
done
echo "✅ Prefunding completed, proceeding with deployment..."

# Clean up and clone repository fresh
echo "🧹 Cleaning up previous repository..."
rm -rf /workspace/cohort-1-assignments-public

cd /workspace

echo "📥 Cloning repository..."
git clone https://github.com/chosunghyun18/cohort-1-assignments-public.git
cd cohort-1-assignments-public

# Fix submodule issues by removing broken submodule references
echo "🔧 Fixing submodule issues..."
# Remove any existing submodule directories
rm -rf lib/forge-std lib/openzeppelin-contracts 2/lib/forge-std

# Remove submodule entries from git config if they exist
git config --remove-section submodule.lib/forge-std 2>/dev/null || true
git config --remove-section submodule.lib/openzeppelin-contracts 2>/dev/null || true
git config --remove-section submodule.2/lib/forge-std 2>/dev/null || true

# Clear any cached submodule references
git rm --cached lib/forge-std 2>/dev/null || true
git rm --cached lib/openzeppelin-contracts 2>/dev/null || true
git rm --cached 2/lib/forge-std 2>/dev/null || true

# Navigate to the correct directory (1a seems to be your main project)
cd 1a

# Initialize forge project if needed
echo "🔧 Initializing Forge project..."
forge init --no-git --force . 2>/dev/null || true

# Install dependencies using forge
echo "📦 Installing dependencies..."
forge install foundry-rs/forge-std --no-git
forge install OpenZeppelin/openzeppelin-contracts --no-git

# Clean previous builds for a fresh build
echo "🧹 Cleaning previous builds..."
forge clean

# Build the project
echo "🔨 Building project..."
forge build

# Deploy the contracts
echo "🚀 Deploying MiniAMM contracts..."
forge script script/MiniAMM.s.sol:MiniAMMScript \
    --rpc-url http://geth:8545 \
    --private-key de3fbeb0b5ee58bcd434755b8e5c0c1f6e96866f4c552414336916c13b09b9f7 \
    --broadcast

echo "✅ Deployment completed!"
echo ""
echo "📊 Contract addresses should be available in the broadcast logs above."

# Extract contract addresses to deployment.json
echo "📝 Extracting contract addresses..."
cd /workspace
node extract-addresses.js

echo "✅ All done! Check deployment.json for contract addresses."