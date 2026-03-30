#!/bin/sh
set -e

WORKSPACE_NAME="${WORKSPACE_NAME:-workspace}"

# Ensure HOME is set; default to /root if not provided
export HOME="${HOME:-/root}"

AUTH_DIR="$HOME/.local/share/opencode"
CONFIG_DIR="$HOME/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"

if [ -n "$NO_COLOR" ]; then
  export TERM=dumb
fi

# Source shared functions
. /entrypoint-common.sh

HOST_INTERNAL=$(get_host_internal)

set_git_credentials
create_auth_json
create_mcp_auth_json
create_config
cd "/$WORKSPACE_NAME" || exit
exec opencode "$@"