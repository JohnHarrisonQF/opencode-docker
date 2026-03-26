#!/bin/sh
set -e

AUTH_DIR="/root/.local/share/opencode"
CONFIG_DIR="/root/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"

if [ -n "$NO_COLOR" ]; then
  export TERM=dumb
fi

get_host_internal() {
  if [ "$CONTAINER_RUNTIME" = "podman" ]; then
    echo "host.containers.internal"
  else
    echo "host.docker.internal"
  fi
}

HOST_INTERNAL=$(get_host_internal)

create_auth_json() {
  mkdir -p "$AUTH_DIR"
  
  FIRST=1
  printf '{' > "$AUTH_DIR/auth.json"
  
  if [ -n "$GITHUB_KEY" ]; then
    printf '"github-copilot":{"type":"oauth","refresh":"%s","access":"%s","expires":0}' \
      "$GITHUB_KEY" "$GITHUB_KEY" >> "$AUTH_DIR/auth.json"
    FIRST=0
  fi
  
  if [ -n "$OLLAMA_API_KEY" ]; then
    if [ $FIRST -eq 0 ]; then
      printf ',' >> "$AUTH_DIR/auth.json"
    fi
    printf '"ollama-cloud":{"type":"api","key":"%s"}' "$OLLAMA_API_KEY" >> "$AUTH_DIR/auth.json"
  fi
  
  printf '}' >> "$AUTH_DIR/auth.json"
}

set_git_credentials() {
  if [ -n "$GIT_NAME" ]; then
    git config --global user.name "$GIT_NAME"
  fi

  if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
  fi
}

create_config() {
  mkdir -p "$CONFIG_DIR/themes"
  
  cat > "$CONFIG_FILE" << 'JSONEOF'
{"$schema":"https://opencode.ai/config.json","model":"ollama-cloud/glm-5:cloud","mcp":{},"theme":"default","plugin":[]}
JSONEOF
  
  if [ "$ENABLE_CONTEXT7" = "true" ]; then
    if [ -n "$CONTEXT7_API_KEY" ]; then
      jq '.mcp.context7 = {"command":["npx","-y","context7-mcp","--api-key",$key],"type":"local","enabled":true}' \
        --arg key "$CONTEXT7_API_KEY" "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    else
      jq '.mcp.context7 = {"command":["context7-mcp"],"type":"local","enabled":true}' \
        "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    fi
  fi
  
  if [ "$ENABLE_SHOPIFY_DEV" = "true" ]; then
    jq '.mcp["shopify-dev-mcp"] = {"command":["shopify-dev-mcp"],"environment":{"OPT_OUT_INSTRUMENTATION":"true"},"type":"local","enabled":true}' \
      "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ "$ENABLE_DDG_SEARCH" = "true" ]; then
    jq '.mcp["ddg-search"] = {"command":["uvx","duckduckgo-mcp-server"],"environment":{"DDG_SAFE_SEARCH":"MODERATE","DDG_REGION":"gb-en"},"type":"local","enabled":true}' \
      "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ "$ENABLE_FIGMA" = "true" ]; then
    if [ -n "$FIGMA_CLIENT_ID" ] && [ -n "$FIGMA_CLIENT_SECRET" ]; then
      jq '.mcp["figma"] = {"url":"https://mcp.figma.com/mcp","type":"remote","enabled":true,"oauth":{"client_id":$cid,"client_secret":$cs}}' \
        --arg cid "$FIGMA_CLIENT_ID" --arg cs "$FIGMA_CLIENT_SECRET" "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    else
      jq '.mcp["figma"] = {"url":"https://mcp.figma.com/mcp","type":"remote","enabled":true}' \
        "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    fi
  fi
  
  if [ "$ENABLE_FIGMA_DESKTOP" = "true" ]; then
    if [ -n "$FIGMA_CLIENT_ID" ] && [ -n "$FIGMA_CLIENT_SECRET" ]; then
      jq '.mcp["figma-desktop"] = {"url":("http://" + $host + ":3845/mcp"),"type":"remote","enabled":true,"oauth":{"client_id":$cid,"client_secret":$cs}}' \
        --arg cid "$FIGMA_CLIENT_ID" --arg cs "$FIGMA_CLIENT_SECRET" --arg host "$HOST_INTERNAL" "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    else
      jq '.mcp["figma-desktop"] = {"url":("http://" + $host + ":3845/mcp"),"type":"remote","enabled":true}' \
        --arg host "$HOST_INTERNAL" "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    fi
  fi
  
  if [ "$ENABLE_INTELLIJ" = "true" ]; then
    jq '.mcp.IntelliJ = {"type":"remote","url":"http://localhost:64342/sse"} | .mcp = (.mcp | to_entries | sort_by(.key == "IntelliJ" | not) | from_entries)' \
      "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ "$ENABLE_SEQUENTIAL_THINKING" = "true" ]; then
    jq '.mcp["sequential-thinking"] = {"command":["npx","-y","@modelcontextprotocol/server-sequential-thinking"],"type":"local","enabled":true}' \
      "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ "$ENABLE_DEVCONTAINERS" = "true" ]; then
    jq '.plugin += ["opencode-devcontainers"]' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ "$ENABLE_DCP" = "true" ]; then
    jq '.plugin += ["@tarquinen/opencode-dcp@latest"]' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ "$THEME" = "dracula" ]; then
    curl -fsSL https://raw.githubusercontent.com/dracula/opencode/main/dracula.json \
      -o "$CONFIG_DIR/themes/dracula.json" 2>/dev/null || true
    jq '. + {"theme": "dracula"}' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  elif [ -n "$THEME" ] && [ "$THEME" != "default" ]; then
    jq --arg theme "$THEME" '.theme = $theme' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
  
  if [ -n "$OLLAMA_PROVIDER_NAME" ] && [ -n "$OLLAMA_PROVIDER_PRETTY_NAME" ] && [ -n "$OLLAMA_HOST" ]; then
    OLLAMA_PROVIDER_NAME="${OLLAMA_PROVIDER_NAME#\"}"; OLLAMA_PROVIDER_NAME="${OLLAMA_PROVIDER_NAME%\"}"
    OLLAMA_PROVIDER_PRETTY_NAME="${OLLAMA_PROVIDER_PRETTY_NAME#\"}"; OLLAMA_PROVIDER_PRETTY_NAME="${OLLAMA_PROVIDER_PRETTY_NAME%\"}"
    OLLAMA_HOST="${OLLAMA_HOST#\"}"; OLLAMA_HOST="${OLLAMA_HOST%\"}"
    OLLAMA_MODELS="${OLLAMA_MODELS#\"}"; OLLAMA_MODELS="${OLLAMA_MODELS%\"}"
    provider_config=$(printf '%s' '{}' | jq --arg npm "@ai-sdk/openai-compatible" --arg name "$OLLAMA_PROVIDER_PRETTY_NAME" --arg baseURL "$OLLAMA_HOST"\
      '. + {npm: $npm, name: $name, options: {baseURL: $baseURL}}')
    if [ -n "$OLLAMA_MODELS" ]; then
      models_obj="{}"
      first=1
      IFS=','
      for model in $OLLAMA_MODELS; do
        if [ $first -eq 1 ]; then
          models_obj=$(printf '%s' "$models_obj" | jq --arg m "$model" '. + {($m): {_launch: true, name: $m}}')
          first=0
        else
          models_obj=$(printf '%s' "$models_obj" | jq --arg m "$model" '. + {($m): {name: $m}}')
        fi
      done
      provider_config=$(printf '%s' "$provider_config" | jq --argjson models "$models_obj" '. + {models: $models}')
      unset IFS
    fi
    jq --arg name "$OLLAMA_PROVIDER_NAME" --argjson config "$provider_config" \
      '.provider[$name] = $config' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
}

set_git_credentials
create_auth_json
create_config
cd /workspace || exit
exec opencode "$@"