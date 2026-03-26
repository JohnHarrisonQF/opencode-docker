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

| Variable | Description | Default |
|----------|-------------|---------|
| `THEME` | UI theme ("default" or "dracula") | `default` |

#### MCP Server Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `INCLUDE_INTELLIJ` | Include IntelliJ MCP server configuration | `true` |
| `ENABLE_CONTEXT7` | Enable Context7 MCP server | `true` |
| `ENABLE_SHOPIFY_DEV` | Enable Shopify Dev MCP server | `true` |
| `ENABLE_DDG_SEARCH` | Enable DuckDuckGo Search MCP server | `true` |
| `CONTEXT7_API_KEY` | Context7 API key for authenticated access | (empty) |

### Custom Themes

If `THEME` is set to a value other than "default" or "dracula", the theme name will be set directly in the configuration. You can manually add theme files to `/root/.config/opencode/themes/` inside the container if needed.

## Usage

### Running OpenCode

After installation, use the `run.sh` script (recommended), or run directly:

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --network host \
  --env-file /path/to/opencode-docker/.env \
  opencode-sandbox
```

**Note:** The container mounts the Docker socket and uses host networking to allow OpenCode to interact with Docker containers on your system.

### Platform-Specific Aliases

**Recommended:** Create an alias pointing to the `run.sh` script (simpler and always up-to-date):

```bash
# Add to your shell config (~/.zshrc, ~/.bashrc, or ~/.bash_profile)
alias opencode='/path/to/opencode-docker/run.sh'
```

**Or use a direct Docker alias:**

**macOS (zsh) - add to `~/.zshrc` or `~/.bash_profile`:**
```bash
alias opencode='docker run -it --rm -v "$(pwd):/workspace" -v /var/run/docker.sock:/var/run/docker.sock --network host --env-file /path/to/opencode-docker/.env opencode-sandbox'
```

**Linux (bash) - add to `~/.bashrc`:**
```bash
alias opencode='docker run -it --rm -v "$(pwd):/workspace" -v /var/run/docker.sock:/var/run/docker.sock --network host --env-file /path/to/opencode-docker/.env opencode-sandbox'
```

**Windows (WSL) - add to `~/.bashrc`:**
```bash
alias opencode='docker run -it --rm -v "$(pwd):/workspace" -v /var/run/docker.sock:/var/run/docker.sock --network host --env-file /path/to/opencode-docker/.env opencode-sandbox'
```

### Using the Included run.sh Script

The repository includes a `run.sh` script that handles building and running:

```bash
./run.sh [opencode arguments]
```

This script will:
1. Load variables from `.env`
2. Check if the Docker image exists (skip build if it does)
3. Run the container with appropriate mounts

**Options:**
- `--build` or `-B` - Force rebuild the Docker image even if it exists

```bash
./run.sh --build
./run.sh -B
```

#### Color Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `NO_COLOR` | Disable colored terminal output | `false` |

## NO_COLOR Support

All scripts respect the `NO_COLOR` environment variable (see [no-color.org](https://no-color.org)). Set this variable to disable colored output:

```bash
export NO_COLOR=1
./run.sh
```

## Building Custom Images

You can build custom Docker images with specific configurations using build arguments:

```bash
docker build \
  --build-arg INCLUDE_INTELLIJ=true \
  --build-arg ENABLE_CONTEXT7=true \
  --build-arg ENABLE_SHOPIFY_DEV=true \
  --build-arg ENABLE_DDG_SEARCH=true \
  --build-arg THEME=dracula \
  --build-arg OLLAMA_PROVIDER_NAME=my-ollama \
  --build-arg OLLAMA_PROVIDER_PRETTY_NAME="My Ollama" \
  --build-arg OLLAMA_HOST=http://my-server:11434 \
  --build-arg OLLAMA_MODELS=model1,model2 \
  -t my-opencode .
```

**Note:** API keys and other sensitive data should be set via environment variables at runtime (via `.env` file or `-e` flags), not as build arguments.

## Troubleshooting

### OpenCode Not Installed

If OpenCode is not installed on your system and you declined automatic installation, you can install it manually:

```bash
curl -fsSL https://opencode.ai/install | bash
```

Or visit the documentation: https://opencode.ai/docs#install

### Docker Permission Issues

If you encounter permission errors with Docker, ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker $USER
```

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