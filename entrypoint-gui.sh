#!/bin/sh
set -e

WORKSPACE_NAME="${WORKSPACE_NAME:-workspace}"

# GUI mode entrypoint
# Runs OpenCode Desktop with X11/Wayland forwarding

# Use container's home directory where config files and theme directories exist
# Defaults to opencode user's home, but allows override via environment
export HOME="${HOME:-/home/opencode}"

# Create home directory structure for arbitrary UID
mkdir -p "$HOME/.config/opencode/themes" "$HOME/.local/share/opencode" 2>/dev/null || true

AUTH_DIR="$HOME/.local/share/opencode"
CONFIG_DIR="$HOME/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"

# Source shared functions
. /entrypoint-common.sh

HOST_INTERNAL=$(get_host_internal)

set_git_credentials
create_auth_json
create_mcp_auth_json
create_config

cd "/$WORKSPACE_NAME" || exit 1

# Handle GTK/libadwaita theme for window decorations
# libadwaita uses portal settings by default - must disable to respect GTK_THEME
: "${GTK_THEME:=Adwaita}"
export GTK_THEME

# For GTK4/libadwaita apps, copy theme CSS files if available
setup_gtk4_theme() {
  theme_name="$1"
  theme_dir="/usr/share/themes/$theme_name"
  if [ -d "$theme_dir/gtk-4.0" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp -r "$theme_dir/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/" 2>/dev/null || true
    cp -r "$theme_dir/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/" 2>/dev/null || true
    cp -r "$theme_dir/assets" "$HOME/.config/" 2>/dev/null || true
  fi
}

# Convert -dark suffix to GTK4 variant syntax for proper dark mode
case "$GTK_THEME" in
  Dracula|Dracula-dark)
    # Setup Dracula theme for GTK4/libadwaita (installed as Dracula-dark)
    setup_gtk4_theme "Dracula-dark"
    export GTK_THEME="Dracula-dark"
    # Force dark color scheme preference
    mkdir -p "$HOME/.config/glib-2.0/settings"
    export GSETTINGS_BACKEND=keyfile
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    # Set cursor theme
    export XCURSOR_THEME="Colloid-Dark"
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nInherits=Colloid-Dark\n' > "$HOME/.icons/default/index.theme" 2>/dev/null || true
    ;;
  *-dark)
    base_theme="${GTK_THEME%-dark}"
    export GTK_THEME="${base_theme}:dark"
    
    # Configure gsettings to prefer dark (needed for libdecor/libadwaita)
    mkdir -p "$HOME/.config/glib-2.0/settings"
    export GSETTINGS_BACKEND=keyfile
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    
    # Setup GTK4 theme files for libadwaita
    setup_gtk4_theme "$base_theme"
    ;;
esac

# Force libadwaita to use GTK_THEME instead of portal/GSettings
export ADW_DISABLE_PORTAL=1

# Fix: OpenCode disables decorations on Wayland by default
# Force native decorations (minimize/maximize/close buttons)
: "${OC_LINUX_DECORATIONS:=native}"
export OC_LINUX_DECORATIONS

# Ensure gsettings schemas are available for libadwaita
if [ -d "/usr/share/glib-2.0/schemas" ]; then
  export GSETTINGS_SCHEMA_DIR="/usr/share/glib-2.0/schemas"
fi

# Enable Client-Side Decorations for GTK3 on Wayland
export GTK_CSD=1

# Force Wayland backend for GTK (not auto)
if [ -n "$WAYLAND_DISPLAY" ]; then
  export GDK_BACKEND=wayland
fi

# Debug: Show libdecor plugin directory
if [ -d "/usr/lib/x86_64-linux-gnu/libdecor-0/plugins-1" ]; then
  export LIBDECOR_PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/libdecor-0/plugins-1"
fi

# Launch OpenCode Desktop
exec OpenCode "$@"