FROM ghcr.io/anomalyco/opencode:latest

ARG ENABLE_INTELLIJ=true
ARG ENABLE_CONTEXT7=true
ARG ENABLE_SHOPIFY_DEV=true
ARG ENABLE_DDG_SEARCH=true
ARG ENABLE_FIGMA=true
ARG ENABLE_FIGMA_DESKTOP=true
ARG THEME=default
ARG OLLAMA_PROVIDER_NAME
ARG OLLAMA_PROVIDER_PRETTY_NAME
ARG OLLAMA_HOST
ARG OLLAMA_MODELS
ARG NPM_PACKAGES
ARG PHP_VERSION
ARG APK_PACKAGES="nodejs npm curl jq git"
ARG REQUIRES_PYTHON=false

RUN if [ -n "$ENABLE_DDG_SEARCH" ]; then \
      REQUIRES_PYTHON=true; \
    fi

RUN if [ -n "$PHP_VERSION" ]; then \
        APK_PACKAGES="$APK_PACKAGES php${PHP_VERSION} php${PHP_VERSION}-dom php${PHP_VERSION}-xml php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-tokenizer php${PHP_VERSION}-pdo php${PHP_VERSION}-pdo_mysql composer"; \
    fi && \
    if [ "$REQUIRES_PYTHON" = "true" ]; then \
        APK_PACKAGES="$APK_PACKAGES python3 py3-pip"; \
    fi && \
    apk add --no-cache $APK_PACKAGES

RUN npm install -g @upstash/context7-mcp @shopify/dev-mcp @ai-sdk/openai-compatible gsd-opencode

RUN if [ "$ENABLE_CONTEXT7" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES @upstash/context7-mcp"; \
    fi && \
    if [ "$ENABLE_SHOPIFY_DEV" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES @shopify/dev-mcp"; \
    fi && \
    if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        NPM_PACKAGES="$NPM_PACKAGES duckduckgo-mcp-server"; \
    fi && \
    if [ -n "$NPM_PACKAGES" ]; then \
        npm install -g $NPM_PACKAGES; \
    fi

RUN if [ -n "$ENABLE_DDG_SEARCH" ]; then \
      pip install --break-system-packages uv \
    fi

RUN mkdir -p /root/.config/opencode/themes

RUN echo '{"$schema":"https://opencode.ai/config.json","model":"ollama-cloud/glm-5:cloud","mcp":{},"theme":"default"}' > /root/.config/opencode/opencode.json

RUN if [ "$ENABLE_CONTEXT7" = "true" ]; then \
        jq '.mcp.context7 = {"command":["context7-mcp"],"type":"local","enabled":true}' \
            /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ "$ENABLE_SHOPIFY_DEV" = "true" ]; then \
        jq '.mcp["shopify-dev-mcp"] = {"command":["shopify-dev-mcp"],"environment":{"OPT_OUT_INSTRUMENTATION":"true"},"type":"local","enabled":true}' \
            /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ "$ENABLE_DDG_SEARCH" = "true" ]; then \
        jq '.mcp["ddg-search"] = {"command":["uvx","duckduckgo-mcp-server"],"environment":{"DDG_SAFE_SEARCH":"MODERATE","DDG_REGION":"gb-en"},"type":"local","enabled":true}' \
            /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ "$ENABLE_FIGMA" = "true" ]; then \
        jq '.mcp["figma"] = {"url": "https://mcp.figma.com/mcp","type":"remote","enabled":true}' \
            /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ "$ENABLE_FIGMA_DESKTOP" = "true" ]; then \
        jq '.mcp["figma-desktop"] = {"url": "http://127.0.0.1:3845/mcp","type":"remote","enabled":true}' \
            /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ "$ENABLE_INTELLIJ" = "true" ]; then \
        jq '.mcp.IntelliJ = {"type": "remote", "url": "http://localhost:64342/sse"} | .mcp = (.mcp | to_entries | sort_by(.key == "IntelliJ" | not) | from_entries)' \
          /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ "$THEME" = "dracula" ]; then \
        curl -fsSL https://raw.githubusercontent.com/dracula/opencode/main/dracula.json \
          -o /root/.config/opencode/themes/dracula.json && \
        jq '. + {"theme": "dracula"}' /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    elif [ "$THEME" != "default" ] && [ -n "$THEME" ]; then \
        jq --arg theme "$THEME" '.theme = $theme' /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

RUN if [ -n "$OLLAMA_PROVIDER_NAME" ] && [ -n "$OLLAMA_PROVIDER_PRETTY_NAME" ] && [ -n "$OLLAMA_HOST" ]; then \
        provider_config=$(echo '{}' | jq --arg npm "@ai-sdk/openai-compatible" --arg name "$OLLAMA_PROVIDER_PRETTY_NAME" --arg baseURL "$OLLAMA_HOST"\
            '. + {npm: $npm, name: $name, options: {baseURL: $baseURL}}'); \
        if [ -n "$OLLAMA_MODELS" ]; then \
            models_obj="{}"; \
            first=1; \
            IFS=','; \
            for model in $OLLAMA_MODELS; do \
                if [ $first -eq 1 ]; then \
                    models_obj=$(echo "$models_obj" | jq --arg m "$model" '. + {($m): {_launch: true, name: $m}}'); \
                    first=0; \
                else \
                    models_obj=$(echo "$models_obj" | jq --arg m "$model" '. + {($m): {name: $m}}'); \
                fi; \
            done; \
            provider_config=$(echo "$provider_config" | jq --argjson models "$models_obj" '. + {models: $models}'); \
            unset IFS; \
        fi; \
        jq --arg name "$OLLAMA_PROVIDER_NAME" --argjson config "$provider_config" \
            '.provider[$name] = $config' /root/.config/opencode/opencode.json > /tmp/opencode.json && \
        mv /tmp/opencode.json /root/.config/opencode/opencode.json; \
    fi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN gsd-opencode install --global

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
