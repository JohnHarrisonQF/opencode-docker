#!/bin/sh
AUTH_DIR="/root/.local/share/opencode"

if [ -n "$NO_COLOR" ]; then
  export TERM=dumb
fi

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

configure_mcp_servers() {
  CONFIG_FILE="/root/.config/opencode/opencode.json"
  
  if [ -n "$CONTEXT7_API_KEY" ] && [ -f "$CONFIG_FILE" ]; then
    if jq -e '.mcp.context7' "$CONFIG_FILE" > /dev/null 2>&1; then
      jq --arg key "$CONTEXT7_API_KEY" \
        '.mcp.context7.command = ["npx", "-y", "@upstash/context7-mcp", "--api-key", $key]' \
        "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    fi
  fi
  
  if [ -n "$FIGMA_CLIENT_ID" ] && [ -n "$FIGMA_CLIENT_SECRET" ] && [ -f "$CONFIG_FILE" ]; then
    if jq -e '.mcp.figma' "$CONFIG_FILE" > /dev/null 2>&1; then
      jq --arg cid "$FIGMA_CLIENT_ID" --arg cs "$FIGMA_CLIENT_SECRET" \
        '.mcp.figma.oauth = {"client_id": $cid, "client_secret": $cs}' \
        "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    fi
    if jq -e '.mcp["figma-desktop"]' "$CONFIG_FILE" > /dev/null 2>&1; then
      jq --arg cid "$FIGMA_CLIENT_ID" --arg cs "$FIGMA_CLIENT_SECRET" \
        '.mcp["figma-desktop"].oauth = {"client_id": $cid, "client_secret": $cs}' \
        "$CONFIG_FILE" > /tmp/opencode.json && \
      mv /tmp/opencode.json "$CONFIG_FILE"
    fi
  fi
}

set_git_credentials
create_auth_json
configure_mcp_servers
cd /workspace || exit
exec opencode "$@"