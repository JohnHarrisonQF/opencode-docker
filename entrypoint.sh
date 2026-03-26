#!/bin/sh
AUTH_DIR="/root/.local/share/opencode"

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

  if  && [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
  fi
}

set_git_credentials
create_auth_json
exec opencode "$@"