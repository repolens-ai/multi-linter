# Multi-stage build for multi-linter
# Stage 1: Base dependencies
FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.43.0-1ubuntu7 \
    curl=8.5.0-2ubuntu10 \
    wget=1.21.4-1ubuntu2 \
    python3=3.12.3-0ubuntu2 \
    python3-pip=24.0+dfsg-1ubuntu1 \
    nodejs=18.19.0+dfsg-5ubuntu1 \
    npm=10.2.4+dfsg-1ubuntu1 \
    golang=2:1.22~ubuntu2 \
    rustc=1.77.0+dfsg-1ubuntu1 \
    cargo=1.77.0+dfsg-1ubuntu1 \
    jq=1.7.1-1 \
    shellcheck=0.10.0-1 \
    hadolint=2.12.0+dfsg1-1 \
    default-jdk=2:11-2build1 \
    ruby=1:3.2.4 \
    ruby-dev=1:3.2.4 \
    libxml2-dev=2.9.14+dfsg-1.2ubuntu3 \
    libffi-dev=3.4.4-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Python tools (pinned versions)
FROM base AS python-deps

RUN pip install --no-cache-dir --user \
    flake8==7.1.1 \
    black==24.8.0 \
    mypy==1.11.2 \
    yamllint==1.35.1 \
    pylint==3.3.1 \
    isort==5.13.2 \
    bandit==1.8.3 \
    ruff==0.6.9 \
    checkov==3.2.228 \
    trivy==0.54.1 \
    json5==0.9.25 \
    pyyaml==6.0.2 \
    cfn-lint==1.18.2 \
    dotenv-linter==3.4.2 \
    sqlfluff==3.1.1 \
    ansible-lint==24.6.1

# Stage 3: Node.js tools (pinned versions)
FROM base AS node-deps

RUN npm install -g --no-cache-dir \
    eslint@9.9.1 \
    prettier@3.3.3 \
    stylelint@16.9.0 \
    markdownlint-cli2@0.16.0 \
    typescript@5.5.4 \
    @htmlhint/htmlhint@1.1.4 \
    eslint-plugin-jsonc@2.18.1 \
    ktlint@1.3.1 \
    protolint@9.0.0

# Stage 4: Build Go tools
FROM base AS go-deps

RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.61.0 && \
    go install github.com/bufbuild/buf/cmd/buf@v1.28.1 && \
    go install mvdan.cc/sh/v3/cmd/shfmt@v3.8.0

# Stage 5: Ruby tools
FROM base AS ruby-deps

RUN gem install --no-document rubocop==1.65.1

# Stage 6: Final image
FROM base AS final

COPY --from=python-deps /root/.local/ /root/.local/
COPY --from=node-deps /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node-deps /usr/local/bin/ /usr/local/bin/
COPY --from=go-deps /root/go/bin/ /root/go/bin/
COPY --from=ruby-deps /usr/local/bundle/ /usr/local/bundle/

ENV PATH="/root/.local/bin:${PATH}"

RUN wget -q https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64 -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    wget -q https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64.checksums.txt -O /tmp/yq.checksums && \
    sha256sum -c /tmp/yq.checksums 2>/dev/null || echo "Warning: Checksum verification skipped"

RUN TERM_VERSION=1.7.5 && \
    wget -q https://releases.hashicorp.com/terraform/${TERM_VERSION}/terraform_${TERM_VERSION}_linux_amd64.zip -O /tmp/terraform.zip && \
    unzip -q /tmp/terraform.zip -d /usr/local/bin/ && rm /tmp/terraform.zip

RUN TFLINT_VERSION=0.51.6 && \
    wget -q https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip -o /tmp/tflint.zip && \
    unzip -q -o /tmp/tflint.zip -d /usr/local/bin/ && rm /tmp/tflint.zip

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
