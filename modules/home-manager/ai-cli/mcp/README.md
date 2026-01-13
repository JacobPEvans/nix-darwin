# MCP Servers - Nix-Native Configuration

All MCP servers are built/fetched and cached at Nix evaluation time. No runtime npm,
npx, or bunx - everything is deterministic and reproducible.

## Architecture

- **Native nixpkgs packages**: terraform-mcp-server, github-mcp-server
  - Referenced directly with `pkgs.package-name`
  - Always up-to-date with nixpkgs version

- **Fetched from GitHub**: Official MCP servers from `modelcontextprotocol/servers`
  - Single fetch of entire repo, pinned to specific commit
  - Fetched once and cached in `/nix/store`

- **npm packages via npx**: For servers not in official repo or nixpkgs
  - Uses `${pkgs.nodejs}/bin/npx -y @package/name` pattern
  - Example: Context7 for documentation lookup

## Enabling Servers

Edit `modules/home-manager/ai-cli/mcp/default.nix` and set `enabled = true`
for the servers you want to use.

```nix
# Example: Enable a nixpkgs package
github = mkServerDef {
  enabled = true;
  command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
};

# Example: Enable an official MCP server
docker = officialServerDef {
  name = "docker";
  enabled = true;
};
```

## Secrets Management

Servers requiring API keys read them from environment variables at runtime.
Use your secrets manager (Doppler, Keychain, 1Password, etc.) to inject env vars.

Required env vars are documented in comments above each server definition.
The config does NOT store any secrets - it only references the server binaries.

## Updating the MCP Servers Repo Hash

When updating to a newer commit of `modelcontextprotocol/servers`:

1. Update the `rev` in `mcpServersRepo` to the new commit SHA
2. Set `sha256 = lib.fakeHash;` temporarily
3. Build to get the correct hash:

   ```bash
   darwin-rebuild switch --flake . 2>&1 | grep "got: sha256"
   ```

4. Replace `lib.fakeHash` with the actual hash from the error message

## Adding New Servers

1. Determine the server source:
   - Check if it's in nixpkgs: `nix search nixpkgs mcp-server`
   - Check if it's in `modelcontextprotocol/servers` repo
   - Otherwise, use npx pattern for npm packages

2. For nixpkgs packages:

   ```nix
   my-server = mkServerDef {
     enabled = false;
     command = "${pkgs.my-mcp-server}/bin/my-mcp-server";
   };
   ```

3. For official MCP servers (modelcontextprotocol/servers):

   ```nix
   my-server = officialServerDef {
     name = "my-server";  # Directory name in src/
     enabled = false;
   };
   ```

4. For npm packages not in the official repo:

   ```nix
   my-server = mkServerDef {
     enabled = false;
     command = "${pkgs.nodejs}/bin/npx";
     args = [ "-y" "@my-org/mcp-server" ];
   };
   ```

## Performance

- **First build**: Fetches repos and caches in `/nix/store`
- **Subsequent builds**: Cache hit - instant
- **Zero runtime overhead**: All servers ready to use immediately

## Troubleshooting

### "hash mismatch" error

The cached hash doesn't match. Update the hash using the method above.

### "not found" when running server

Node.js servers: Check `${pkgs.nodejs}/bin/node` path
Native packages: Verify package exists: `nix search nixpkgs package-name`

### Server not loading in Claude Code

1. Check `enabled = true` in mcp/default.nix
2. Run `darwin-rebuild switch --flake .`
3. Restart Claude Code
4. Verify in Claude Code: check `/mcp` command
