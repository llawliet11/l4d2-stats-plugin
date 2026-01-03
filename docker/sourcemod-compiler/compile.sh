#!/bin/bash

# SourceMod Plugin Compiler Script for Docker
# Usage: docker run -v $(pwd):/workspace sourcemod-compiler [plugin_name]

set -e

COMPILER="/sourcemod/addons/sourcemod/scripting/spcomp"
INCLUDES="-i /workspace/scripting/include -i /sourcemod/addons/sourcemod/scripting/include -i /includes -i /workspace/scripting"

echo "🔨 SourceMod Plugin Compiler (Docker)"
echo "====================================="

# Check if spcomp exists
if [ ! -f "$COMPILER" ]; then
    echo "❌ Error: spcomp not found at $COMPILER"
    exit 1
fi

# Function to compile a single plugin
compile_plugin() {
    local plugin_name="$1"
    local sp_file="scripting/${plugin_name}.sp"
    local smx_file="plugins/${plugin_name}.smx"
    
    if [ ! -f "$sp_file" ]; then
        echo "❌ Error: $sp_file not found"
        return 1
    fi
    
    echo "📝 Compiling: $plugin_name.sp"
    
    # Create plugins directory if it doesn't exist
    mkdir -p plugins
    
    if $COMPILER "$sp_file" -o "$smx_file" $INCLUDES; then
        if [ -f "$smx_file" ]; then
            local size=$(ls -lh "$smx_file" | awk '{print $5}')
            echo "✅ Success: $smx_file ($size)"
        else
            echo "❌ Compilation failed - no output file created"
            return 1
        fi
    else
        echo "❌ Compilation failed"
        return 1
    fi
}

# Check if specific plugin is provided
if [ $# -eq 1 ]; then
    plugin_name="${1%.sp}"  # Remove .sp extension if provided
    compile_plugin "$plugin_name"
else
    # Compile all plugins
    echo "🔍 Compiling all plugins..."
    for sp_file in scripting/*.sp; do
        if [ -f "$sp_file" ]; then
            plugin_name=$(basename "$sp_file" .sp)
            compile_plugin "$plugin_name"
        fi
    done
fi

echo ""
echo "📁 Compiled plugins are in: plugins/"
echo "🚀 Ready to deploy to your L4D2 server!"
