FROM ghcr.io/anomalyco/opencode:latest

ARG ENABLE_INTELLIJ=true
ARG ENABLE_CONTEXT7=true
ARG ENABLE_SHOPIFY_DEV=true
ARG ENABLE_DDG_SEARCH=true
ARG PHP_VERSION
ARG ENABLE_DDG_SEARCH=true
ARG ENABLE_GSD=true
ARG ENABLE_DEVCONTAINERS=false
ARG APK_PACKAGES="nodejs npm curl jq git"
ARG NPM_PACKAGES="@ai-sdk/openai-compatible"

RUN if [ -n "$PHP_VERSION" ]; then \
        APK_PACKAGES="$APK_PACKAGES php${PHP_VERSION} php${PHP_VERSION}-dom php${PHP_VERSION}-xml php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-tokenizer php${PHP_VERSION}-session php${PHP_VERSION}-pdo php${PHP_VERSION}-pdo_mysql composer"; \
    fi && \
    if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        APK_PACKAGES="$APK_PACKAGES python3 py3-pip"; \
    fi && \
    apk add --no-cache $APK_PACKAGES

RUN if [ "$ENABLE_CONTEXT7" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES @upstash/context7-mcp"; \
    fi && \
    if [ "$ENABLE_SHOPIFY_DEV" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES @shopify/dev-mcp"; \
    fi && \
    if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES duckduckgo-mcp-server"; \
    fi && \
    if [ "$ENABLE_GSD" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES gsd-opencode"; \
    fi && \
    if [ "$ENABLE_DEVCONTAINERS" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES @devcontainers/cli"; \
    fi && \
    if [ -n "$NPM_PACKAGES" ]; then \
        npm install -g $NPM_PACKAGES; \
    fi

RUN if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        pip install --break-system-packages uv; \
    fi

RUN if [ "$ENABLE_GSD" = "true" ]; then \
        gsd-opencode install --global; \
    fi

# Create non-root user for arbitrary UID/GID support
# Sticky bit (1777) allows writes but prevents deletion of others' files
RUN adduser -D -h /home/opencode opencode && \
    chmod 1777 /home/opencode

COPY entrypoint-common.sh /entrypoint-common.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]