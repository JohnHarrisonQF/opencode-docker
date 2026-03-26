FROM ghcr.io/anomalyco/opencode:latest

ARG INCLUDE_INTIJ=true
ARG THEME=default
ARG OLLAMA_PROVIDER_NAME
ARG OLLAMA_PROVIDER_PRETTY_NAME
ARG OLLAMA_HOST
ARG OLLAMA_MODELS

RUN apk add --no-cache nodejs npm curl jq python3 py3-pip php composer

RUN npm install -g @upstash/context7-mcp @shopify/dev-mcp @ai-sdk/openai-compatible gsd-opencode

RUN pip install --break-system-packages uv

RUN mkdir -p /root/.config/opencode/themes

RUN echo '{"$schema":"https://opencode.ai/config.json","model":"ollama-cloud/glm-5:cloud","mcp":{"context7":{"command":["context7-mcp"],"type":"local","enabled":true},"shopify-dev-mcp":{"command":["shopify-dev-mcp"],"environment":{"OPT_OUT_INSTRUMENTATION":"true"},"type":"local","enabled":true},"ddg-search":{"command":["uvx","duckduckgo-mcp-server"],"environment":{"DDG_SAFE_SEARCH":"MODERATE","DDG_REGION":"gb-en"},"type":"local","enabled":true}},"theme":"default"}' > /root/.config/opencode/opencode.json

RUN if [ "$INCLUDE_INTIJ" = "true" ]; then \
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

ENTRYPOINT ["/entrypoint.sh"]
