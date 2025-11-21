# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a chezmoi-managed dotfiles repository for cross-platform (Linux/Windows) configuration management. Chezmoi manages dotfiles by keeping source files here and applying them to the home directory.

## Common Commands

```bash
chezmoi apply              # Apply changes to home directory
chezmoi apply -n           # Dry-run (preview changes)
chezmoi diff               # Show differences between source and destination
chezmoi edit <file>        # Edit a managed file
chezmoi add <file>         # Add a file to chezmoi management
chezmoi cd                 # Open shell in source directory
```

## Repository Structure

- **`.chezmoiscripts/`** - Scripts that run during `chezmoi apply`
  - `linux/` - Linux-only install scripts (run_onchange_*.tmpl)
  - `windows/` - Windows-only PowerShell scripts
- **`.chezmoidata/packages.yaml`** - Package lists for different contexts (work/personal)
- **`.chezmoi.toml.tmpl`** - Chezmoi configuration template (sets email based on hostname)
- **`.chezmoiignore.tmpl`** - Platform-conditional file ignoring
- **`dot_*`** - Files that become dotfiles (e.g., `dot_gitconfig` → `~/.gitconfig`)
- **`AppData/`** and **`OneDrive/`** - Windows-specific configs (ignored on Linux)

## Key Conventions

- Files with `.tmpl` suffix are Go templates processed by chezmoi
- `run_onchange_` prefix scripts only run when their content changes
- Hostname `MikesDesktop` triggers personal email; otherwise uses work email
- `$codespaces` variable detects GitHub Codespaces environment

## MCP Server Configuration

This repository manages MCP (Model Context Protocol) servers for both Claude Desktop and Claude Code via chezmoi:

- **`dot_config/Claude/claude_desktop_config.json.tmpl`** - MCP config for Claude Desktop
- **`dot_claude/settings.json.tmpl`** - Settings for Claude Code (includes MCP config)
- **`dot_vscode/mcp.json.tmpl`** - Legacy VSCode user-level MCP config
- **`.chezmoiscripts/linux/run_onchange_install_mcp_servers.sh.tmpl`** - Installs MCP dependencies

### Available MCP Servers

All MCP servers use Docker for isolation and consistency:

**Claude Desktop** (full feature set):
- **fetch** - Web content fetching capabilities
- **filesystem** - File system operations with home directory mounted
- **git** - Git repository operations with home directory mounted

**Claude Code** (minimal set, IDE provides native file/git access):
- **fetch** - Web content fetching capabilities only

### Setup

1. Ensure Docker is running on your system

2. Apply chezmoi configuration:
   ```bash
   chezmoi apply
   ```

3. Restart Claude Desktop or Claude Code to load MCP servers

### Adding New MCP Servers

Edit the respective template files and add your server configuration. Docker-based example:
```json
"server-name": {
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-v",
    "{{ .chezmoi.homeDir }}:{{ .chezmoi.homeDir }}",
    "mcp/server-name"
  ]
}
```
