# L4D2 Stats Plugin Makefile for Mac M3 Max
# Provides easy compilation commands

.PHONY: help compile compile-docker compile-native compile-online setup-docker setup-native clean

# Default target
help:
	@echo "🔨 L4D2 Stats Plugin Compiler (Mac M3 Max)"
	@echo "=========================================="
	@echo ""
	@echo "Available commands:"
	@echo "  make compile          - Compile all plugins using Docker (recommended)"
	@echo "  make compile-docker   - Compile using Docker"
	@echo "  make compile-native   - Compile using native compiler (if available)"
	@echo "  make compile-online   - Instructions for online compilation"
	@echo "  make setup-docker     - Setup Docker compiler"
	@echo "  make setup-native     - Setup native compiler"
	@echo "  make clean           - Clean compiled plugins"
	@echo ""
	@echo "Examples:"
	@echo "  make compile                    # Compile all plugins"
	@echo "  make compile PLUGIN=l4d2_stats_recorder  # Compile specific plugin"

# Default compilation method (Docker)
compile: compile-docker

# Docker compilation
compile-docker:
	@echo "🐳 Compiling with Docker..."
ifdef PLUGIN
	./compile-plugins.sh $(PLUGIN)
else
	./compile-plugins.sh
endif

# Native compilation
compile-native:
	@echo "🖥️  Compiling with native compiler..."
	@if [ ! -f ~/sourcemod-compiler/addons/sourcemod/scripting/spcomp ]; then \
		echo "❌ Native compiler not found. Run 'make setup-native' first."; \
		exit 1; \
	fi
ifdef PLUGIN
	@echo "Compiling $(PLUGIN).sp..."
	~/sourcemod-compiler/addons/sourcemod/scripting/spcomp \
		scripting/$(PLUGIN).sp \
		-o plugins/$(PLUGIN).smx \
		-i scripting/include \
		-i ~/sourcemod-compiler/addons/sourcemod/scripting/include \
		-i ~/l4d2-includes
else
	@echo "Compiling all plugins..."
	@for sp_file in scripting/*.sp; do \
		if [ -f "$$sp_file" ]; then \
			plugin_name=$$(basename "$$sp_file" .sp); \
			echo "Compiling $$plugin_name.sp..."; \
			~/sourcemod-compiler/addons/sourcemod/scripting/spcomp \
				"$$sp_file" \
				-o "plugins/$$plugin_name.smx" \
				-i scripting/include \
				-i ~/sourcemod-compiler/addons/sourcemod/scripting/include \
				-i ~/l4d2-includes; \
		fi; \
	done
endif

# Online compilation instructions
compile-online:
	@echo "🌐 Online Compilation Instructions:"
	@echo "1. Visit: https://www.sourcemod.net/compiler.php"
	@echo "2. Upload your .sp file"
	@echo "3. Download the compiled .smx file"
	@echo "4. Place it in the plugins/ directory"
	@echo ""
	@echo "Available plugins to compile:"
	@for sp_file in scripting/*.sp; do \
		if [ -f "$$sp_file" ]; then \
			plugin_name=$$(basename "$$sp_file" .sp); \
			echo "  - $$plugin_name.sp"; \
		fi; \
	done

# Setup Docker compiler
setup-docker:
	@echo "🐳 Setting up Docker compiler..."
	@if ! docker info > /dev/null 2>&1; then \
		echo "❌ Docker is not running. Please start Docker Desktop."; \
		exit 1; \
	fi
	cd docker/sourcemod-compiler && docker build -t sourcemod-compiler .
	@echo "✅ Docker compiler setup completed!"

# Setup native compiler
setup-native:
	@echo "🖥️  Setting up native compiler..."
	./setup-native-compiler.sh

# Clean compiled plugins
clean:
	@echo "🧹 Cleaning compiled plugins..."
	rm -f plugins/*.smx
	@echo "✅ Cleaned!"

# List available plugins
list:
	@echo "📝 Available plugins:"
	@for sp_file in scripting/*.sp; do \
		if [ -f "$$sp_file" ]; then \
			plugin_name=$$(basename "$$sp_file" .sp); \
			echo "  - $$plugin_name"; \
		fi; \
	done
