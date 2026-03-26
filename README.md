# OpenCode Docker

A hastily built Docker-based installation wrapper for OpenCode, allowing you to run OpenCode in an isolated container environment.

## Disclaimer

This project is not affiliated with, endorsed by, or connected to the OpenCode team. This is an independent community project that wraps OpenCode in a Docker container for convenience. For the official OpenCode project, visit [opencode.ai](https://opencode.ai).

## Prerequisites

- Docker (required)
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
| `OLLAMA_MODEL`                | Default model to use (currently defaults to `ollama-cloud/glm-5:cloud`) | No                                   |

#### Git Setup

| Variable    | Description                | Required |
|-------------|----------------------------|----------|
| `GIT_NAME`  | Your name for Git commits  | No       |
| `GIT_EMAIL` | Your email for Git commits | No       |

#### Theme Settings

| Variable | Description                                | Default   |
|----------|--------------------------------------------|-----------|
| `THEME`  | UI theme (any built in theme or "dracula") | `default` |

#### MCP Server Configuration

| Variable             | Description                               | Default |
|----------------------|-------------------------------------------|---------|
| `INCLUDE_INTELLIJ`   | Include IntelliJ MCP server configuration | `true`  |
| `ENABLE_CONTEXT7`    | Enable Context7 MCP server                | `true`  |
| `ENABLE_SHOPIFY_DEV` | Enable Shopify Dev MCP server             | `true`  |
| `ENABLE_DDG_SEARCH`  | Enable DuckDuckGo Search MCP server       | `true`  |
| `CONTEXT7_API_KEY`   | Context7 API key for authenticated access | (empty) |

#### Colour Settings

| Variable   | Description                                                                | Default |
|------------|----------------------------------------------------------------------------|---------|
| `NO_COLOR` | Disable colored terminal output (see [no-color.org](https://no-color.org)) | `false` |

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

This project uses and depends on:
- [OpenCode](https://opencode.ai) - Base image (`ghcr.io/anomalyco/opencode:latest`)
- [context7-mcp](https://www.npmjs.com/package/@upstash/context7-mcp) by Upstash
- [shopify-dev-mcp](https://www.npmjs.com/package/@shopify/dev-mcp) by Shopify
- [@ai-sdk/openai-compatible](https://www.npmjs.com/package/@ai-sdk/openai-compatible) by Vercel
- [gsd-opencode](https://www.npmjs.com/package/gsd-opencode) by rokicool
- [duckduckgo-mcp-server](https://github.com/nickclyde/duckduckgo-mcp-server) by nickclyde
- [Dracula Theme](https://github.com/dracula/opencode) for OpenCode - MIT License

See respective package documentation for licence information.

## Links

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Installation](https://opencode.ai/docs#install)
- [Docker Hub](https://hub.docker.com/)