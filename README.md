# OpenCode Docker

A hastily built Docker-based installation wrapper for OpenCode, allowing you to run OpenCode in an isolated container environment.

Currently using local OpenCode to handle some auth tasks, this requirement should be dropped eventually.

## Disclaimer

This project is in active development, expect breakages.

> This project is not affiliated with, endorsed by, or connected to the OpenCode team. This is an independent community project that wraps OpenCode in a Docker container for convenience. For the official OpenCode project, visit [opencode.ai](https://opencode.ai).

## Prerequisites

- Docker or Podman (required)
- Git (for installation)
- OpenCode (optional – the installer can install it for you)

## Quick Start

### Automated Installation

Run the installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/JohnHarrisonQF/opencode-docker/main/install.sh | bash
```

After installation, add an alias to your shell config:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias opencode-docker='/path/to/opencode-docker/run.sh'
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/JohnHarrisonQF/opencode-docker.git
   ```

2. Copy the example environment file:
   ```bash
   cd opencode-docker
   cp .env.example .env
   ```

3. Edit the `.env` file with your configuration:
   ```bash
   nano .env
   ```

4. Create an alias in your shell config:
   ```bash
   # Add to ~/.zshrc or ~/.bashrc
   alias opencode-docker='/path/to/opencode-docker/run.sh'
   ```

## Configuration

The `.env` file in the opencode-docker directory contains all configuration:

```bash
cd /path/to/opencode-docker
nano .env  # or use your preferred editor
```

### Environment Variables

#### Provider Credentials

| Variable         | Description              | Required |
|------------------|--------------------------|----------|
| `OLLAMA_API_KEY` | API key for Ollama Cloud | No       |
| `GITHUB_KEY`     | GitHub Copilot API key   | No       |

#### Ollama Settings

| Variable                      | Description                                                           | Required                             |
|-------------------------------|-----------------------------------------------------------------------|--------------------------------------|
| `OLLAMA_PROVIDER_NAME`        | Provider identifier (e.g., "ollama")                                  | No (required if using custom Ollama) |
| `OLLAMA_PROVIDER_PRETTY_NAME` | Display name (e.g. "Ollama")                                          | No (required if using custom Ollama) |
| `OLLAMA_HOST`                 | Ollama server URL (e.g. "http://localhost:11434")                     | No (required if using custom Ollama) |
| `OLLAMA_MODELS`               | Comma-separated list of models (first model gets `_launch: true`)     | No                                   |

#### Git Setup

| Variable    | Description                | Required |
|-------------|----------------------------|----------|
| `GIT_NAME`  | Your name for Git commits  | No       |
| `GIT_EMAIL` | Your email for Git commits | No       |

#### Container Settings

| Variable      | Description                                                                                                   | Required |
|---------------|---------------------------------------------------------------------------------------------------------------|----------|
| `PHP_VERSION` | PHP version to install in the container (format: `XY`, e.g. `84` for PHP 8.4). Leave blank to not install PHP | No       |

#### Theme Settings

| Variable | Description                                | Default   |
|----------|--------------------------------------------|-----------|
| `THEME`  | UI theme (any built in theme or "dracula") | `default` |

#### MCP Server Configuration

| Variable                     | Description                                           | Default |
|------------------------------|-------------------------------------------------------|---------|
| `ENABLE_INTELLIJ`            | Enable IntelliJ MCP server                            | `false` |
| `ENABLE_CONTEXT7`            | Enable Context7 MCP server                            | `false` |
| `ENABLE_SHOPIFY_DEV`         | Enable Shopify Dev MCP server                         | `false` |
| `ENABLE_DDG_SEARCH`          | Enable DuckDuckGo Search MCP server                   | `false` |
| `ENABLE_CLICKUP`             | Enable ClickUp MCP server                             | `false` |
| `ENABLE_FIGMA`               | Enable Figma MCP server                               | `false` |
| `ENABLE_FIGMA_DESKTOP`       | Enable Figma Desktop MCP server                       | `false` |
| `ENABLE_SEQUENTIAL_THINKING` | Enable Sequential Thinking MCP server                 | `false` |
| `ENABLE_GSD`                 | Enable GSD (GSD-OpenCode) MCP server                  | `false` |
| `ENABLE_DEVCONTAINERS`       | Enable opencode-devcontainers plugin                  | `false` |
| `ENABLE_DCP`                 | Enable Dynamic Context Pruning plugin                 | `false` |
| `CONTEXT7_API_KEY`           | Context7 API key for authenticated access             | (empty) |
| `FIGMA_CLIENT_ID`            | Figma OAuth client ID (required if Figma enabled)     | (empty) |
| `FIGMA_CLIENT_SECRET`        | Figma OAuth client secret (required if Figma enabled) | (empty) |

**Note:** MCP servers are configured at runtime. No rebuild needed to enable/disable - just restart the container.

**Network Mode:** When `ENABLE_INTELLIJ=true`, the container uses `--network host` to allow connections to IntelliJ running on the host.

#### Colour Settings

| Variable   | Description                                                                 | Default |
|------------|-----------------------------------------------------------------------------|---------|
| `NO_COLOR` | Disable coloured terminal output (see [no-color.org](https://no-color.org)) | `false` |

### Custom Themes

If `THEME` is set to a value that is not one of the built-in OpenCode themes or "dracula" you will need to provide the cutom theme.

## Usage

### Setup

Create a shell alias pointing to `run.sh`:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias opencode-docker='/path/to/opencode-docker/run.sh'
```

Reload your shell config:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

### Running

Navigate to any project folder and run:

```bash
cd /path/to/your-project
opencode-docker
```

The current directory is mounted as `/workspace` inside the container. OpenCode will operate on your project files.

**Rebuild the image:**
```bash
opencode-docker --build
```

**Force Docker or Podman:**
```bash
opencode-docker --docker    # Use Docker explicitly
opencode-docker --podman    # Use Podman explicitly
```

### GUI Mode

For users who prefer a graphical interface over the terminal UI, use the `--gui` flag:

```bash
opencode-docker --gui
```

This launches OpenCode Desktop in a container with X11/Wayland display forwarding.

**Prerequisites for GUI mode:**

- **Linux X11:** Ensure `DISPLAY` environment variable is set (usually automatic)
- **Linux Wayland:** Ensure `WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR` are set
- **macOS:** Install and run [XQuartz](https://www.xquartz.org/):
  ```bash
  brew install --cask xquartz
  # Start XQuartz, then enable network connections in Preferences > Security
  export DISPLAY=:0
  ```
- **Windows:**
  - **Windows 11 + WSL2 (recommended):** WSLg is built-in. Run from WSL2:
    ```bash
    # In WSL2, DISPLAY and WAYLAND_DISPLAY are auto-set
    opencode-docker --gui
    ```
  - **Windows 10 or Docker Desktop:** Install an X server:
    ```bash
    # Install VcXsrv or Xming on Windows
    # Start with "Disable access control" enabled
    export DISPLAY=host.docker.internal:0
    opencode-docker --gui
    ```

**GUI vs TUI mode:**

| Mode   | Command                | Interface     | Container User |
|--------|------------------------|---------------|----------------|
| TUI    | `opencode-docker`      | Terminal UI   | root           |
| GUI    | `opencode-docker --gui`| Desktop app  | host UID/GID   |

**Security note:** GUI mode mounts the X11 socket read-only and runs as your host user for proper file permissions.

**Windows Docker Desktop setup (if WSLg unavailable):**

1. Install [VcXsrv](https://sourceforge.net/projects/vcxsrv/) or [Xming](https://sourceforge.net/projects/xming/)
2. Start VcXsrv/Xming with "Disable access control" checked
3. In Docker Desktop: Settings > General > Enable "Expose daemon on tcp://localhost:2375"
4. Set DISPLAY: `export DISPLAY=host.docker.internal:0`
5. Run: `opencode-docker --gui`

## Container Runtime

The script auto-detects your container runtime:
1. Checks for `docker` first
2. Falls back to `podman` if docker isn't found

podman is experimental, expect (more) issues

You can override with `--docker` or `--podman` flags.

## Security Considerations

**Network Isolation:**
- By default, the container uses bridge networking for isolation
- When `ENABLE_INTELLIJ=true`, `--network host` is used to connect to IntelliJ on localhost
- Host networking bypasses container network isolation
- For local development workstations, this is typically acceptable

**File System:**
- Only the current working directory is mounted to `/workspace`
- Secrets are passed via environment variables

## Troubleshooting

### OpenCode Not Installed

If OpenCode is not installed on your system, and you declined automatic installation, you can install it manually:

```bash
curl -fsSL https://opencode.ai/install | bash
```

Or visit the documentation: https://opencode.ai/docs#install

### Docker Permission Issues

If you encounter permission errors with Docker, ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker $USER
```

## License

This project is licensed under the MIT Licence - see the [LICENCE](LICENSE) file for details.

## Attribution

### Core Dependencies

These projects are always installed in the container:

- [OpenCode](https://opencode.ai) - Base image (`ghcr.io/anomalyco/opencode:latest`)
- [@ai-sdk/openai-compatible](https://www.npmjs.com/package/@ai-sdk/openai-compatible) by Vercel

### Runtime Dependencies

These are required on your host machine:

- [Docker](https://www.docker.com/) or [Podman](https://podman.io/) - Container runtime
- Docker Compose or podman-compose - Container orchestration (optional)

### Optional MCP Servers

These are installed when enabled via environment variables:

- [context7-mcp](https://www.npmjs.com/package/@upstash/context7-mcp) by Upstash - Enabled with `ENABLE_CONTEXT7=true`
- [shopify-dev-mcp](https://www.npmjs.com/package/@shopify/dev-mcp) by Shopify - Enabled with `ENABLE_SHOPIFY_DEV=true`
- [duckduckgo-mcp-server](https://github.com/nickclyde/duckduckgo-mcp-server) by nickclyde - Enabled with `ENABLE_DDG_SEARCH=true`
- [ClickUp MCP](https://developer.clickup.com/docs/connect-an-ai-assistant-to-clickups-mcp-server-1) - Enabled with `ENABLE_CLICKUP=true`
- [gsd-opencode](https://www.npmjs.com/package/gsd-opencode) by rokicool - Enabled with `ENABLE_GSD=true`
- [@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking) - Enabled with `ENABLE_SEQUENTIAL_THINKING=true`

### Optional Plugins

These are enabled via environment variables:

- [opencode-devcontainers](https://github.com/athal7/opencode-devcontainers) - Enabled with `ENABLE_DEVCONTAINERS=true`
- [opencode-dynamic-context-pruning](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning) - Enabled with `ENABLE_DCP=true`

### Themes

- [Dracula Theme](https://github.com/dracula/opencode) for OpenCode - MIT Licence. Enabled with `THEME=dracula`

See respective package documentation for licence information.

## Links

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Installation](https://opencode.ai/docs#install)
- [Docker Hub](https://hub.docker.com/)