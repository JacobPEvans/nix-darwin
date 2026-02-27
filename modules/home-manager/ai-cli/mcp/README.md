# MCP Servers - Nix-Native Configuration

MCP server definitions are declared in `default.nix` and deployed to `~/.claude.json`
automatically on every `darwin-rebuild switch` via a `home.activation` script.

**Nix is the sole manager of user-scoped MCP servers.** Any entries added manually via
`claude mcp add --scope user` will be overwritten on the next rebuild.

## Transports

### stdio (local processes)

Run a local command as the MCP server. Use the `official` helper for Anthropic servers,
or write inline attribute sets for custom servers:

```nix
# Official Anthropic server via bunx
fetch = official "fetch";

# nixpkgs binary (resolved via PATH)
github = { command = "github-mcp-server"; };

# npm package via bunx
context7 = {
  command = "bunx";
  args = [ "@context7/mcp-server" ];
};
```

### SSE / HTTP (remote servers)

Connect to a running HTTP server using SSE or HTTP transport:

```nix
# SSE server
cribl = {
  type = "sse";
  url = "http://localhost:30030/mcp";
};

# HTTP server with custom headers
my-server = {
  type = "http";
  url = "http://localhost:8080/mcp";
  headers = { Authorization = "Bearer \${TOKEN}"; };
};
```

## Enabling / Disabling Servers

All servers are enabled by default (`disabled = false` is the module system default).
To disable a server, set `disabled = true`:

```nix
postgresql = official "postgres" // { disabled = true; };
```

To enable a disabled server without editing `default.nix`, override via the module system.
Because the catalog uses plain assignments (priority 100), the override must use `lib.mkForce`
to win the merge:

```nix
programs.claude.mcpServers.postgresql.disabled = lib.mkForce false;
```

## Secrets Management

Servers requiring API keys read them from environment variables at runtime.
Use your secrets manager (Doppler, Keychain, 1Password, etc.) to inject env vars.

Required env vars are documented in comments above each server definition.
The config does NOT store any secrets — it only references commands and URLs.

## Adding New Servers

1. Choose the transport:
   - Local stdio process → inline attribute set with `command` (and optionally `args`)
   - Remote SSE/HTTP endpoint → inline attribute set with `type` and `url`

2. New servers are enabled by default. Add `// { disabled = true; }` to start disabled.

3. Run `darwin-rebuild switch --flake .` to deploy.

4. Verify: `cat ~/.claude.json | jq .mcpServers`

## Troubleshooting

### Server not appearing in Claude Code

1. Check `disabled` is not set to `true` in `mcp/default.nix`
2. Run `darwin-rebuild switch --flake .`
3. Restart Claude Code
4. Check `~/.claude.json` contains the server: `jq .mcpServers ~/.claude.json`

### SSE server shows connection error

Expected when the remote server is not running (e.g., OrbStack k8s is stopped).
The server definition is still deployed — it will connect when the server is available.

### "command not found" for a stdio server

Verify the binary is in PATH. For nixpkgs packages, ensure it's installed in your profile
or system packages. For bunx/uvx, ensure bun/uv is installed.
