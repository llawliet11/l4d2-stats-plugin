#!/bin/bash

# SourceMod Compiler using Docker Compose
# Usage: ./compile-docker-compose.sh [plugin_name]

set -e

echo "🐳 SourceMod Compiler (Docker Compose)"
echo "======================================"

# Change to docker directory
cd docker/sourcemod-compiler

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker not found. Please install Docker."
        exit 1
    fi
    # Use docker compose (newer syntax)
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Build image if it doesn't exist
echo "🏗️  Building compiler image if needed..."
$DOCKER_COMPOSE build

# Run compilation
if [ $# -eq 1 ]; then
    # Compile specific plugin
    plugin_name="${1%.sp}"  # Remove .sp extension if provided
    echo "📝 Compiling: $plugin_name.sp"
    $DOCKER_COMPOSE --profile tools run --rm sourcemod-compiler \
        /usr/local/bin/compile.sh "$plugin_name"
else
    # Compile all plugins
    echo "📝 Compiling all plugins..."
    $DOCKER_COMPOSE --profile tools run --rm sourcemod-compiler
fi

echo ""
echo "✅ Compilation completed!"
echo "📁 Check the plugins/ directory for compiled .smx files"
