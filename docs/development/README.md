# Development Documentation

This directory contains documentation for developers working on the L4D2 Stats Plugin.

## Available Guides

- **[COMPILE_INSTRUCTIONS.md](COMPILE_INSTRUCTIONS.md)** - SourceMod plugin compilation
  - SourcePawn compiler setup
  - Plugin building process
  - Deployment instructions

## Development Workflow

1. **Local Development**: Edit code on your local machine
2. **Compilation**: Use the provided scripts to compile plugins
3. **Testing**: Deploy to test server environment
4. **Remote Debugging**: Use SSH access for server-side debugging

## Code Organization

- `/scripting/` - SourceMod plugin source code
- `/plugins/` - Compiled plugin files (.smx)
- `/website-api/` - Node.js API backend
- `/website-ui/` - Vue.js frontend application