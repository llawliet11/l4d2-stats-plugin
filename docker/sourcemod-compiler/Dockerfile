# SourceMod Compiler for Mac M3 Max
# Uses Ubuntu with x86_64 emulation for compatibility
FROM --platform=linux/amd64 ubuntu:20.04

# Install dependencies including 32-bit libraries for spcomp
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    build-essential \
    libc6-i386 \
    lib32stdc++6 \
    lib32gcc-s1 \
    lib32ncurses6 \
    lib32z1 \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /sourcemod

# Download SourceMod stable build
RUN wget -O sourcemod.tar.gz \
    "https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git7210-linux.tar.gz" \
    && tar -xzf sourcemod.tar.gz \
    && rm sourcemod.tar.gz

# Create includes directory and download common includes
RUN mkdir -p /includes

# Note: Left4DHooks includes will be provided by local project includes
# The compilation script will use local includes from the project

# Make spcomp executable
RUN chmod +x /sourcemod/addons/sourcemod/scripting/spcomp

# Create compilation script
COPY compile.sh /usr/local/bin/compile.sh
RUN chmod +x /usr/local/bin/compile.sh

# Set working directory for compilation
WORKDIR /workspace

# Default command
CMD ["/usr/local/bin/compile.sh"]
