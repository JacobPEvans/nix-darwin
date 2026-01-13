# MCP Servers - Nix-Native Configuration

All MCP servers are built/fetched and cached at Nix evaluation time. No runtime npm,
npx, or bunx - everything is deterministic and reproducible.

## Architecture

- **Native nixpkgs packages**: terraform-mcp-server, github-mcp-server, docker, etc.
  - Referenced directly with `pkgs.package-name`
  - Always up-to-date with nixpkgs version

- **Fetched from GitHub**: Official MCP servers from modelcontextprotocol
  - `modelcontextprotocol/servers` - Official Anthropic MCP servers
  - Fetched once and cached in `/nix/store`

## Enabling Servers

Edit `modules/home-manager/ai-cli/mcp/default.nix` and set `enable = true`
for the servers you want to use.

```nix
# Example: Enable a server
github = mkServer {
  enabled = true;
  command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
};
```

## Secrets Management

Servers requiring API keys read them from environment variables at runtime.
Use your secrets manager (Doppler, Keychain, 1Password, etc.) to inject env vars.

Required env vars are documented in comments above each server definition.
The config does NOT store any secrets - it only references the server binaries.

## Updating Hashes

When you add a new server or update the GitHub revisions, you'll need to generate
correct hashes for the `fetchFromGitHub` calls.

### Method 1: Let Nix calculate the hash

1. Build your configuration:

   ```bash
   darwin-rebuild switch --flake . 2>&1 | grep "got: sha256"
   ```

2. Copy the hash from the error message
3. Replace `lib.fakeHash` with the actual hash

### Method 2: Pre-calculate the hash

```bash
nix-hash --flat --sri --type sha256 \
  $(nix flake prefetch --json github:modelcontextprotocol/servers main | jq -r '.storePath')
```

## Adding New Servers

1. Determine the server source:
   - Check if it's in nixpkgs: `nix search nixpkgs mcp-server`
   - Otherwise, find it in modelcontextprotocol/servers repo

2. For nixpkgs packages:

   ```nix
   my-server = mkServer {
     enabled = false;
     command = "${pkgs.my-mcp-server}/bin/my-mcp-server";
   };
   ```

3. For GitHub servers:

   ```nix
   my-server = (officialServer {
     name = "my-server";
     hash = lib.fakeHash;
   }) // { enable = false; };
   ```

4. Run `darwin-rebuild switch --flake .` to calculate the hash

## Performance

- **First build**: Fetches repos and caches in `/nix/store`
- **Subsequent builds**: Cache hit - instant
- **Zero runtime overhead**: All servers ready to use immediately

## Troubleshooting

### "hash mismatch" error

The cached hash doesn't match. Generate new hash (Method 1 above).

### "not found" when running server

Node.js servers: Check `${pkgs.nodejs}/bin/node` path
Native packages: Verify package exists: `nix search nixpkgs package-name`

### Server not loading in Claude Code

1. Check `enable = true` in mcp/default.nix
2. Run `darwin-rebuild switch --flake .`
3. Restart Claude Code
4. Verify in Claude Code: check `/mcp` command
