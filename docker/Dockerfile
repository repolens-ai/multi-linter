FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    git curl wget python3 python3-pip nodejs npm golang rustc cargo jq \
    && apt-get clean

# Install Python linters
RUN pip install flake8 black mypy yamllint --break-system-packages

# Install Node.js linters
RUN npm install -g eslint prettier

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Install Go linter
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Setup Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy scripts and linters
COPY scripts/ /usr/local/bin/
COPY linters/ /usr/local/bin/
COPY config/ /tmp/config/
RUN chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
