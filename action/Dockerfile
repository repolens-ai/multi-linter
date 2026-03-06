# Multi-stage build for multi-linter
# Stage 1: Base dependencies
FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    nodejs \
    npm \
    golang \
    rustc \
    cargo \
    jq \
    shellcheck \
    default-jdk \
    ruby \
    ruby-dev \
    libxml2-dev \
    libffi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Python tools (pinned versions)
FROM base AS python-deps

RUN pip install --no-cache-dir --break-system-packages \
    flake8 \
    black \
    mypy \
    yamllint \
    pylint \
    isort \
    bandit \
    ruff \
    pyyaml \
    cfn-lint \
    sqlfluff

# Stage 3: Node.js tools
FROM base AS node-deps

RUN npm install -g --no-cache-dir \
    eslint \
    prettier \
    stylelint \
    markdownlint-cli2 \
    typescript \
    @htmlhint/htmlhint

# Stage 4: Build Go tools
FROM base AS go-deps

RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Stage 5: Ruby tools
FROM base AS ruby-deps

RUN gem install --no-document rubocop

# Stage 6: Final image
FROM base AS final

COPY --from=python-deps /usr/local/bin/ /usr/local/bin/
COPY --from=python-deps /usr/local/lib/ /usr/local/lib/
COPY --from=node-deps /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node-deps /usr/local/bin/ /usr/local/bin/
COPY --from=go-deps /root/go/bin/ /root/go/bin/
COPY --from=ruby-deps /usr/local/bundle/ /usr/local/bundle/

RUN wget -q https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64 -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

RUN groupadd -r linter && useradd -r -g linter linter

COPY scripts/ /usr/local/bin/
COPY linters/ /usr/local/bin/
COPY config/ /tmp/config/
RUN chmod +x /usr/local/bin/*.sh

USER linter
WORKDIR /app

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
