#!/bin/sh
set -e

# GUI mode entrypoint
# Runs OpenCode Desktop with X11/Wayland forwarding

# Override HOME from host - we need to use container's home directory
# where config files and theme directories exist
export HOME="/home/opencode"

# Create home directory structure for arbitrary UID
mkdir -p "$HOME/.config/opencode/themes" "$HOME/.local/share/opencode" 2>/dev/null || true

AUTH_DIR="$HOME/.local/share/opencode"
CONFIG_DIR="$HOME/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"

# Setup git credentials if provided
if [ -n "$GIT_NAME" ]; then
    git config --global user.name "$GIT_NAME"
fi

if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
fi

create_config() {
  mkdir -p "$CONFIG_DIR/themes"
  
  cat > "$CONFIG_FILE" << 'JSONEOF'
{"$schema":"https://opencode.ai/config.json","model":"ollama-cloud/glm-5:cloud","mcp":{},"theme":"default","plugin":[]}
JSONEOF
  
  if [ "$THEME" = "dracula" ]; then
    curl -fsSL https://raw.githubusercontent.com/dracula/opencode/main/dracula.json \
      -o "$CONFIG_DIR/themes/dracula.json" 2>/dev/null || true
    jq '. + {"theme": "dracula"}' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  elif [ -n "$THEME" ] && [ "$THEME" != "default" ]; then
    jq --arg theme "$THEME" '.theme = $theme' "$CONFIG_FILE" > /tmp/opencode.json && \
    mv /tmp/opencode.json "$CONFIG_FILE"
  fi
}

create_config

# Change to workspace directory
cd /workspace || exit 1

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