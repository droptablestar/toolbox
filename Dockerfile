FROM ubuntu:24.04

ARG GOSU_VERSION=1.17

ENV DEBIAN_FRONTEND=noninteractive
ENV PUID=99
ENV PGID=100

# Base packages from Ubuntu repos
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
    # Spell checking (Emacs flyspell -> hunspell + en_US dictionary)
    hunspell \
    hunspell-en-us \
    # Video tools
    ffmpeg \
    mediainfo \
    mkvtoolnix \
    handbrake-cli \
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
    fzf \
    # Third-party repo prereqs
    ca-certificates \
    gnupg \
    lsb-release \
    # Intel GPU / QSV
    intel-media-va-driver \
    vainfo \
    && rm -rf /var/lib/apt/lists/*

# Emacs 30 from PPA. Ubuntu 24.04 ships 29.x, whose tree-sitter tops out at
# grammar ABI 14; the current python grammar is ABI 15. 30.x supports ABI 15
# and matches the dev workstation (30.2).
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ubuntuhandbook1/emacs \
    && apt-get update && apt-get install -y emacs-nox \
    && rm -rf /var/lib/apt/lists/*

# Tree-sitter grammars baked into the image (built with Emacs 30 -> ABI 15) so
# they are not a runtime step and do not depend on the mounted HOME. The Emacs
# config adds /usr/local/lib/tree-sitter to treesit-extra-load-path.
RUN mkdir -p /usr/local/lib/tree-sitter \
    && emacs -Q --batch --eval "(progn \
         (setq treesit-extra-load-path '(\"/usr/local/lib/tree-sitter\")) \
         (setq treesit-language-source-alist \
               '((python \"https://github.com/tree-sitter/tree-sitter-python\" \"v0.23.6\") \
                 (yaml \"https://github.com/ikatyang/tree-sitter-yaml\"))) \
         (dolist (lang '(python yaml)) \
           (treesit-install-language-grammar lang \"/usr/local/lib/tree-sitter\")))"

# GitHub CLI + Docker CLI (require keyring setup before install)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y \
        gh \
        docker-ce-cli \
        docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Make 'fd' available as 'fd' instead of 'fdfind'
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Node 20 + npm globals
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm config set prefix /usr/local \
    && npm install -g opencode-ai @anthropic-ai/claude-code pyright \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*
ENV XDG_CACHE_HOME=/tmp/.cache

# gosu for privilege dropping in entrypoint
RUN curl -fsSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" \
        -o /usr/local/bin/gosu \
    && chmod +x /usr/local/bin/gosu \
    && gosu --version

# Standalone binaries (yt-dlp, lazygit, ruff)
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
        -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp \
    && LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/') \
    && curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
        | tar xz -C /usr/local/bin lazygit \
    && curl -fsSL https://github.com/astral-sh/ruff/releases/latest/download/ruff-x86_64-unknown-linux-gnu.tar.gz \
        | tar xz --strip-components=1 -C /usr/local/bin ruff-x86_64-unknown-linux-gnu/ruff

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
