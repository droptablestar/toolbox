FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    # Core utilities
    git \
    curl \
    wget \
    unzip \
    zip \
    rsync \
    htop \
    tree \
    jq \
    tmux \
    screen \
    sudo \
    # Emacs
    emacs-nox \
    # Video tools
    ffmpeg \
    mediainfo \
    mkvtoolnix \
    handbrake-cli \
    yt-dlp \
    # Python
    python3 \
    python3-pip \
    libmfx-gen1.2 \
    onevpl-tools \
    # Network tools
    net-tools \
    iputils-ping \
    dnsutils \
    openssh-client \
    # Build tools
    build-essential \
    cmake \
    # File management
    fd-find \
    ripgrep \
    # Docker dependencies
    ca-certificates \
    gnupg \
    lsb-release \
    # Intel GPU / QSV
    intel-media-va-driver \
    vainfo \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y \
    docker-ce-cli \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Make 'fd' available as 'fd' instead of 'fdfind'
RUN ln -s $(which fdfind) /usr/local/bin/fd

# add Node 20 + opencode
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g opencode-ai \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*
ENV XDG_CACHE_HOME=/tmp/.cache
# optional but recommended in your container environment
# ENV OPENCODE_DISABLE_DEFAULT_PLUGINS=true

RUN apt-get update && apt-get install -y curl ffmpeg python3 \
 && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp \
 && chmod a+rx /usr/local/bin/yt-dlp

CMD ["/bin/bash"]


