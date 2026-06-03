# Use the modern bubuntux image
FROM ghcr.io/bubuntux/nordvpn:latest

# Switch to root to install tools
USER root

# Install the tools you want to use inside the VPN
# We install curl, wget, python, pip, git, and nano/vim
# Install EVERYTHING in one go
RUN apt-get update && \
    # 1. Install Basic Tools
    apt-get install -y \
    curl \
    wget \
    tinyproxy \
    python3 \
    python3-pip \
    python3-venv \
    git \
    nano \
    iputils-ping \
    procps \
    # 2. Install Font Dependencies
    software-properties-common && \
    # 3. Accept EULA and Install Fonts
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get install -y --no-install-recommends \
    ttf-mscorefonts-installer \
    fonts-liberation \
    libgbm1 \
    libasound2 && \
    # 4. Clean up at the very end
    rm -rf /var/lib/apt/lists/*

# Create the scripts directory
WORKDIR /scripts

# (Optional) Make sure scripts are executable by default
RUN chmod -R 755 /scripts