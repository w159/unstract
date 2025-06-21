#!/bin/bash

# Get the absolute path of the project's root directory
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

echo "╔══════════════════════════════════════════╗"
echo "║        UNSTRACT QUICK START              ║"
echo "║   No-code LLM Platform for Documents     ║"
echo "╚══════════════════════════════════════════╝"

echo ""
echo "Starting Unstract setup..."
echo ""

# Run the setup script
"$PROJECT_ROOT/scripts/setup/setup-environment.sh"

# Check if setup was successful before deploying
if [ $? -eq 0 ]; then
    echo "✅ Environment setup complete."
    echo "🚀 Deploying Unstract..."
    "$PROJECT_ROOT/scripts/deploy/deploy-unstract.sh"
else
    echo "❌ Environment setup failed. Aborting deployment."
    exit 1
fi

echo "✅ Unstract deployment finished."