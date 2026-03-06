FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    git curl wget python3 python3-pip nodejs npm golang rustc cargo jq \
    shellcheck hadolint default-jdk ruby ruby-dev \
    libxml2-dev libcurl4-openssl-dev libffi-dev \
    && apt-get clean

# Install Python linters
RUN pip install flake8 black mypy yamllint pylint isort bandit ruff \
    checkov trivy json5 pyyaml --break-system-packages

# Install Node.js linters
RUN npm install -g eslint prettier stylelint markdownlint-cli typescript \
    @eslint/json @htmlhint/htmlhint commitlint actionlint \
    eslint-plugin-jsonc markdownlint-cli

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Install Go linter
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Install ktlint
RUN npm install -g ktlint

# Install terraform and tflint
RUN wget -q https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip -O /tmp/terraform.zip && \
    unzip -q /tmp/terraform.zip -d /usr/local/bin/ && rm /tmp/terraform.zip
RUN wget -q https://github.com/terraform-linters/tflint/releases/download/v0.50.0/tflint_linux_amd64.zip -O /tmp/tflint.zip && \
    unzip -q /tmp/tflint.zip -d /usr/local/bin/ && rm /tmp/tflint.zip

# Install cfn-lint
RUN pip install cfn-lint --break-system-packages

# Install dotenv-linter
RUN pip install dotenv-linter --break-system-packages

# Install sqlfluff
RUN pip install sqlfluff --break-system-packages

# Install ansible-lint
RUN pip install ansible-lint --break-system-packages

# Install dotnet SDK for C# and .NET
RUN wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 && \
    rm /tmp/dotnet-install.sh
ENV PATH="/root/.dotnet:${PATH}"

# Install RuboCop for Ruby
RUN gem install rubocop

# Install luacheck for Lua
RUN luarocks install luacheck

# Install chktex for LaTeX
RUN apt-get update && apt-get install -y chktex && apt-get clean

# Setup Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy scripts and linters
COPY scripts/ /usr/local/bin/
COPY linters/ /usr/local/bin/
COPY config/ /tmp/config/
RUN chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
