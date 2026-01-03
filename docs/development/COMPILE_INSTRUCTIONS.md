# SourceMod Plugin Compilation Instructions for Ubuntu 24

## Prerequisites

Your Ubuntu 24 server should have:
- Basic build tools
- wget/curl for downloading
- SSH access

## Step 1: Sync Your Code to Ubuntu Server

```bash
# From your local machine, sync the project to Ubuntu server
rsync -avz -e "ssh -p YOUR_SSH_PORT" \
  --exclude=".git" \
  --exclude="node_modules" \
  --exclude=".DS_Store" \
  --exclude=".vscode" \
  --exclude=".idea" \
  --exclude=".env*" \
  ./ USERNAME@YOUR_SERVER_IP:/home/USERNAME/projects/GAMES/left4dead2-stats
```

## Step 2: Install Required Dependencies on Ubuntu

```bash
# SSH into your Ubuntu server
ssh USERNAME@YOUR_SERVER_IP -p YOUR_SSH_PORT

# Update package list
sudo apt update

# Install required packages for 32-bit compatibility
sudo apt install -y wget tar lib32stdc++6 libc6-i386 lib32gcc-s1

# Create workspace directory
mkdir -p ~/sourcemod-compiler
cd ~/sourcemod-compiler
```

## Step 3: Download SourceMod Compiler

```bash
# Download SourceMod (latest stable version)
wget https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git7025-linux.tar.gz

# Extract the compiler
tar -xzf sourcemod-1.12.0-git7025-linux.tar.gz

# Make the compiler executable
chmod +x addons/sourcemod/scripting/spcomp

# Verify installation
./addons/sourcemod/scripting/spcomp --version
```

## Step 4: Get Left4DHooks Include Files

```bash
# Create include directory
mkdir -p ~/l4d2-includes

# Download Left4DHooks include file
wget -O ~/l4d2-includes/left4dhooks.inc \
  "https://raw.githubusercontent.com/SilvDev/Left4DHooks/master/left4dhooks.inc"

# If the above fails, you can copy it from your L4D2 server's sourcemod/scripting/include/
```

## Step 5: Compile the Plugins

```bash
# Navigate to your project directory
cd /home/USERNAME/projects/GAMES/left4dead2-stats

# Compile l4d2_stats_recorder.sp
~/sourcemod-compiler/addons/sourcemod/scripting/spcomp \
  scripting/l4d2_stats_recorder.sp \
  -o plugins/l4d2_stats_recorder.smx \
  -i scripting/include \
  -i ~/sourcemod-compiler/addons/sourcemod/scripting/include \
  -i ~/l4d2-includes

# Compile l4d2_skill_detect.sp
~/sourcemod-compiler/addons/sourcemod/scripting/spcomp \
  scripting/l4d2_skill_detect.sp \
  -o plugins/l4d2_skill_detect.smx \
  -i scripting/include \
  -i ~/sourcemod-compiler/addons/sourcemod/scripting/include \
  -i ~/l4d2-includes

# Verify compilation
ls -la plugins/*.smx
```

## Step 6: Create a Compilation Script

```bash
# Create a convenient compilation script
cat > ~/compile-l4d2-plugins.sh << 'EOF'
#!/bin/bash

# L4D2 Stats Plugin Compiler Script
# Usage: ./compile-l4d2-plugins.sh [plugin_name]

set -e

PROJECT_DIR="/home/USERNAME/projects/GAMES/left4dead2-stats"
COMPILER="$HOME/sourcemod-compiler/addons/sourcemod/scripting/spcomp"
INCLUDES="-i $PROJECT_DIR/scripting/include -i $HOME/sourcemod-compiler/addons/sourcemod/scripting/include -i $HOME/l4d2-includes"

echo "🔨 L4D2 Plugin Compiler"
echo "======================"

cd "$PROJECT_DIR"

compile_plugin() {
    local plugin_name="$1"
    local sp_file="scripting/${plugin_name}.sp"
    local smx_file="plugins/${plugin_name}.smx"
    
    if [ ! -f "$sp_file" ]; then
        echo "❌ Error: $sp_file not found"
        return 1
    fi
    
    echo "📝 Compiling: $plugin_name.sp"
    
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
EOF

# Make script executable
chmod +x ~/compile-l4d2-plugins.sh
```

## Step 7: Usage Examples

```bash
# Compile specific plugin
~/compile-l4d2-plugins.sh l4d2_stats_recorder

# Compile all plugins
~/compile-l4d2-plugins.sh

# Check compilation results
ls -la /home/USERNAME/projects/GAMES/left4dead2-stats/plugins/
```

## Step 8: Sync Compiled Plugins Back to Mac

```bash
# From your local machine, sync the compiled plugins back
rsync -avz -e "ssh -p YOUR_SSH_PORT" \
  USERNAME@YOUR_SERVER_IP:/home/USERNAME/projects/GAMES/left4dead2-stats/plugins/ \
  ./plugins/

# Check the results
ls -la plugins/
git status
```

## Troubleshooting

### If you get "cannot read from file" errors:
1. **Missing includes**: Download the missing .inc files to `~/l4d2-includes/`
2. **Check paths**: Ensure all include directories exist and are accessible

### If you get "undefined symbol" errors:
1. **Extension not loaded**: The plugin may need specific SourceMod extensions
2. **Check dependencies**: Make sure all required extensions are installed on your L4D2 server

### If compilation succeeds but plugins don't load:
1. **Check SourceMod version**: Ensure your L4D2 server has compatible SourceMod version
2. **Check extensions**: Verify required extensions (like Left4DHooks) are installed

## Alternative: One-Line Compilation

```bash
# Quick compilation command (run from project root)
~/sourcemod-compiler/addons/sourcemod/scripting/spcomp \
  scripting/l4d2_stats_recorder.sp \
  -o plugins/l4d2_stats_recorder.smx \
  -i scripting/include \
  -i ~/sourcemod-compiler/addons/sourcemod/scripting/include \
  -i ~/l4d2-includes
```

## Notes

- **File permissions**: Compiled .smx files will have correct Linux permissions
- **Git tracking**: You can commit the compiled .smx files to your git repository
- **Server deployment**: Copy the .smx files to your L4D2 server's `addons/sourcemod/plugins/` directory
- **Dependencies**: Make sure your L4D2 server has the Left4DHooks extension installed

This method is much more reliable than Docker cross-compilation and gives you full control over the compilation process!