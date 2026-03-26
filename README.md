# OpenCode Docker

A Docker-based installation wrapper for OpenCode, allowing you to run OpenCode in an isolated container environment.

## Disclaimer

This project is not affiliated with, endorsed by, or connected to the OpenCode team. This is an independent community project that wraps OpenCode in a Docker container for convenience. For the official OpenCode project, visit [opencode.ai](https://opencode.ai).

## Prerequisites

- Docker (required)
- Git (for installation)
- OpenCode (optional - the installer can install it for you)

## Quick Start

### Automated Installation

Run the installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/JohnHarrisonQF/opencode-docker/main/install.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/JohnHarrisonQF/opencode-docker.git
cd opencode-docker
./install.sh
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/JohnHarrisonQF/opencode-docker.git
   cd opencode-docker
   ```

2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit the `.env` file with your configuration:
   ```bash
   nano .env  # or use your preferred editor
   ```

4. Build and run:
   ```bash
   ./run.sh
   ```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure the following variables:

#### Provider Credentials

| Variable | Description | Required |
|----------|-------------|----------|
| `OLLAMA_API_KEY` | API key for Ollama Cloud | No |
| `GITHUB_KEY` | GitHub Copilot API key | No |

#### Ollama Settings

| Variable | Description | Required |
|----------|-------------|----------|
| `OLLAMA_PROVIDER_NAME` | Provider identifier (e.g., "ollama") | No (required if using custom Ollama) |
| `OLLAMA_PROVIDER_PRETTY_NAME` | Display name (e.g., "Ollama") | No (required if using custom Ollama) |
| `OLLAMA_HOST` | Ollama server URL (e.g., "http://localhost:11434") | No (required if using custom Ollama) |
| `OLLAMA_MODELS` | Comma-separated list of models (first model gets `_launch: true`) | No |
| `OLLAMA_MODEL` | Default model to use (currently defaults to `ollama-cloud/glm-5:cloud`) | No |

#### Git Setup

| Variable | Description | Required |
|----------|-------------|----------|
| `GIT_NAME` | Your name for Git commits | No |
| `GIT_EMAIL` | Your email for Git commits | No |

#### Theme Settings

| Variable | Description                                | Default |
|----------|--------------------------------------------|---------|
| `THEME` | UI theme (any built in theme or "dracula") | `default` |

#### MCP Server Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `INCLUDE_INTELLIJ` | Include IntelliJ MCP server configuration | `true` |
| `ENABLE_CONTEXT7` | Enable Context7 MCP server | `true` |
| `ENABLE_SHOPIFY_DEV` | Enable Shopify Dev MCP server | `true` |
| `ENABLE_DDG_SEARCH` | Enable DuckDuckGo Search MCP server | `true` |
| `CONTEXT7_API_KEY` | Context7 API key for authenticated access | (empty) |

### Custom Themes

If `THEME` is set to a value that is not one of the built in Opencode themes or "dracula" you will need to provide the cutom theme.

## Usage

### Running OpenCode

After installation, use the `run.sh` script (recommended), or run directly:

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --network host \
  --env-file /path/to/opencode-docker/.env \
  opencode-docker
```

**Note:** The container mounts the Docker socket and uses host networking to allow OpenCode to interact with Docker containers on your system.

### Using run.sh

The `run.sh` script handles building and running:

```bash
./run.sh [opencode arguments]
```

**Options:**
- `--build` or `-B` - Force rebuild the Docker image even if it exists

```bash
./run.sh --build
```

**What it does:**
1. Loads variables from `.env`
2. Builds the Docker image if it doesn't exist (or with `--build`)
3. Runs the container with proper mounts and networking

### Recommended Alias

Create a shell alias to `run.sh`:

```bash
# Add to your shell config (~/.zshrc for Linux/macOS, ~/.bashrc for Linux/WSL)
alias opencode-docker='/path/to/opencode-docker/run.sh'
```

#### Colour Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `NO_COLOR` | Disable colored terminal output | `false` |

## NO_COLOR Support

All scripts respect the `NO_COLOR` environment variable (see [no-color.org](https://no-color.org)). Set the `NO_COLOR` environemnt variable to disable coloured output.

**Note:** API keys and other sensitive data should be set via environment variables at runtime (via `.env` file or `-e` flags), not as build arguments.

## Troubleshooting

### OpenCode Not Installed

If OpenCode is not installed on your system and you declined automatic installation, you can install it manually:

```bash
curl -fsSL https://opencode.ai/install | bash
```

Or visit the documentation: https://opencode.ai/docs#install

### Volume Mount Issues

The current working directory is mounted to `/workspace` inside the container. Ensure you're running commands from the correct directory.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Attribution

This project uses and depends on:
- [OpenCode](https://opencode.ai) - Base image (`ghcr.io/anomalyco/opencode:latest`)
- [context7-mcp](https://www.npmjs.com/package/@upstash/context7-mcp) by Upstash
- [shopify-dev-mcp](https://www.npmjs.com/package/@shopify/dev-mcp) by Shopify
- [@ai-sdk/openai-compatible](https://www.npmjs.com/package/@ai-sdk/openai-compatible) by Vercel
- [gsd-opencode](https://www.npmjs.com/package/gsd-opencode)
- [duckduckgo-mcp-server](https://pypi.org/project/duckduckgo-mcp-server/) - Python package for DuckDuckGo search
- [Dracula Theme](https://github.com/dracula/opencode) for OpenCode - MIT License

See respective package documentation for license information.

## Links

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Installation](https://opencode.ai/docs#install)
- [Docker Hub](https://hub.docker.com/)