#!/bin/bash

# This script builds the Vue.js application once and then serves it with Nginx
# It's designed to be used in a Docker container

# Check if the dist directory already exists and has files
if [ -d "/frontend/dist" ] && [ "$(ls -A /frontend/dist)" ]; then
    echo "Dist directory already exists and has files. Skipping build."
else
    corepack enable

    echo "Building Vue.js application..."

    cd /frontend

    # Check if yarn is available
    if command -v yarn &> /dev/null; then
        echo "Using yarn to build..."
        yarn install
        yarn build
    else
        echo "Using npm to build..."
        npm install
        npm run build
    fi

    echo "Build completed."
fi

# Exit with success
exit 0