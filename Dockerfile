FROM ghcr.io/anomalyco/opencode:latest

ARG PHP_VERSION
ARG ENABLE_DDG_SEARCH=true
ARG ENABLE_GSD=true
ARG APK_PACKAGES="nodejs npm curl jq git"

RUN if [ -n "$PHP_VERSION" ]; then \
        APK_PACKAGES="$APK_PACKAGES php${PHP_VERSION} php${PHP_VERSION}-dom php${PHP_VERSION}-xml php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-tokenizer php${PHP_VERSION}-pdo php${PHP_VERSION}-pdo_mysql composer"; \
    fi && \
    if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        APK_PACKAGES="$APK_PACKAGES python3 py3-pip"; \
    fi && \
    apk add --no-cache $APK_PACKAGES

RUN npm install -g @upstash/context7-mcp @shopify/dev-mcp @ai-sdk/openai-compatible

RUN if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        pip install --break-system-packages uv && \
        npm install -g duckduckgo-mcp-server; \
    fi

RUN if [ "$ENABLE_GSD" = "true" ]; then \
        npm install -g gsd-opencode && \
        gsd-opencode install --global; \
    fi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]