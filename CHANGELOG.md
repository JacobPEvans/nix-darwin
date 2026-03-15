# Changelog

## [1.8.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.7.0...v1.8.0) (2026-03-15)


### Bug Fixes

* migrate Bash permissions to space format and expand command tools ([#846](https://github.com/JacobPEvans/nix-darwin/issues/846)) ([48d7e81](https://github.com/JacobPEvans/nix-darwin/commit/48d7e811436fc42b458e4411011e41b23b179847))

## [1.7.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.6.0...v1.7.0) (2026-03-15)


### Bug Fixes

* **ci:** migrate copilot-setup-steps to determinate-nix-action@v3 ([#842](https://github.com/JacobPEvans/nix-darwin/issues/842)) ([63d82ef](https://github.com/JacobPEvans/nix-darwin/commit/63d82efed576f6921a68abfb0aa70ccb0f366f2a))

## [1.6.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.5.0...v1.6.0) (2026-03-15)


### Bug Fixes

* **nix:** use list type for determinateNix.customSettings ([#840](https://github.com/JacobPEvans/nix-darwin/issues/840)) ([29ec20e](https://github.com/JacobPEvans/nix-darwin/commit/29ec20e257dfb95c2b7ebd8ae1ee00472c34b96e))

## [1.5.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.4.0...v1.5.0) (2026-03-14)


### Features

* **nix:** add trusted-users and devenv cachix binary cache ([#837](https://github.com/JacobPEvans/nix-darwin/issues/837)) ([cf31065](https://github.com/JacobPEvans/nix-darwin/commit/cf310650e36d3d773150fad0034b68bd4411e3a4))

## [1.4.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.3.0...v1.4.0) (2026-03-14)


### Features

* migrate flake.lock updates to Renovate nix manager ([#835](https://github.com/JacobPEvans/nix-darwin/issues/835)) ([92bbb71](https://github.com/JacobPEvans/nix-darwin/commit/92bbb71e8b960bab4acd0c6f5bda5d20604c7192))

## [1.3.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.2.0...v1.3.0) (2026-03-14)


### Features

* add APFS volume quota support and AI model volumes ([#832](https://github.com/JacobPEvans/nix-darwin/issues/832)) ([4d0aea3](https://github.com/JacobPEvans/nix-darwin/commit/4d0aea3b6cd6bddc15fc52ae1d9095a3c198f36f))

## [1.2.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.1.0...v1.2.0) (2026-03-13)


### Features

* add Splunk MCP server to Claude Code mcpServers ([#829](https://github.com/JacobPEvans/nix-darwin/issues/829)) ([f212edd](https://github.com/JacobPEvans/nix-darwin/commit/f212edd3660b7dde9f5bb0e134df6857481996b0))
* **gc:** add weekly LaunchDaemon to prune old profile generations ([#830](https://github.com/JacobPEvans/nix-darwin/issues/830)) ([d3cac5b](https://github.com/JacobPEvans/nix-darwin/commit/d3cac5b3e8c2e08fa5429a730e146503b48ce291))

## [1.1.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.0.0...v1.1.0) (2026-03-13)


### Features

* add daily repo health audit agentic workflow ([#822](https://github.com/JacobPEvans/nix-darwin/issues/822)) ([974b393](https://github.com/JacobPEvans/nix-darwin/commit/974b393379a2409cd1c431d55154904a5d25fbb2))
* add Docker daemon log rotation and builder GC config ([#803](https://github.com/JacobPEvans/nix-darwin/issues/803)) ([26e5ca0](https://github.com/JacobPEvans/nix-darwin/commit/26e5ca07dc53c1b3b1c2005010fe0cc5892e0e0f))
* add gh-aw agentic workflows ([#766](https://github.com/JacobPEvans/nix-darwin/issues/766)) ([8489738](https://github.com/JacobPEvans/nix-darwin/commit/8489738fb4333401fe79a0c41edfd4fc4e8e4072))
* add HF_TOKEN to macOS Keychain exports for HuggingFace MCP ([#827](https://github.com/JacobPEvans/nix-darwin/issues/827)) ([9fa5d56](https://github.com/JacobPEvans/nix-darwin/commit/9fa5d56b782f7f802da2a6d8ee69349dc91a4fe5))
* add LM Studio and update nix-ai/nix-home inputs ([4e6c828](https://github.com/JacobPEvans/nix-darwin/commit/4e6c82866afd6124486c70333a4f0c1c4fcde2be))
* disable automatic triggers on Claude-executing workflows ([cbe315e](https://github.com/JacobPEvans/nix-darwin/commit/cbe315ebe544ba3e234cfdf04083cf1ac751a8a4))
* **dock:** add iPhone Mirroring and Microsoft Teams ([#787](https://github.com/JacobPEvans/nix-darwin/issues/787)) ([9c88430](https://github.com/JacobPEvans/nix-darwin/commit/9c8843051214575dfeb50e8f9accc5148a5c6b97))
* extract claudebar package and add nix-update to flake workflow ([#811](https://github.com/JacobPEvans/nix-darwin/issues/811)) ([0992eb4](https://github.com/JacobPEvans/nix-darwin/commit/0992eb4d6085830701829cb3b5c92dabcaca1ba4))
* move module-eval check into lib/checks.nix ([#761](https://github.com/JacobPEvans/nix-darwin/issues/761)) ([3f80d47](https://github.com/JacobPEvans/nix-darwin/commit/3f80d476883387e8633a760643c9bff636885c37))
* **nix:** migrate to official determinateNix module with automatic GC ([#792](https://github.com/JacobPEvans/nix-darwin/issues/792)) ([cdc21c6](https://github.com/JacobPEvans/nix-darwin/commit/cdc21c6ca047fc5cbe8fd4e101b286db5051e790))
* remove nodejs and python310 from global packages ([#765](https://github.com/JacobPEvans/nix-darwin/issues/765)) ([024eab9](https://github.com/JacobPEvans/nix-darwin/commit/024eab9d743c68dbb832f6e8654f79d44c43c356))


### Bug Fixes

* add schedule→dispatch workaround for OIDC bug (claude-code-action[#814](https://github.com/JacobPEvans/nix-darwin/issues/814)) ([#779](https://github.com/JacobPEvans/nix-darwin/issues/779)) ([f6a48d6](https://github.com/JacobPEvans/nix-darwin/commit/f6a48d6f9127a7001d364fc9c1d25b46cc8501bc))
* **ci:** remove jacobpevans-cc-plugins from AI_INPUTS ([#784](https://github.com/JacobPEvans/nix-darwin/issues/784)) ([669c2d8](https://github.com/JacobPEvans/nix-darwin/commit/669c2d83453d4335d795d9f37d2c08b5f727e214))
* **ci:** replace actions/cache with magic-nix-cache-action for Nix store ([#810](https://github.com/JacobPEvans/nix-darwin/issues/810)) ([631162b](https://github.com/JacobPEvans/nix-darwin/commit/631162bbea80b4c465e3a40448936478f31333e6))
* **ci:** use GitHub App token for release-please to trigger CI Gate ([#828](https://github.com/JacobPEvans/nix-darwin/issues/828)) ([7013a0e](https://github.com/JacobPEvans/nix-darwin/commit/7013a0edfe4fb48552a6a9ba6c3629827de043e6))
* correct broken nix repo reference in Renovate troubleshooting docs ([#813](https://github.com/JacobPEvans/nix-darwin/issues/813)) ([e663882](https://github.com/JacobPEvans/nix-darwin/commit/e6638829affb6eb81e617b370c766d0ffe4c8b54))
* disable hash pinning for trusted actions, use version tags ([#790](https://github.com/JacobPEvans/nix-darwin/issues/790)) ([94630a1](https://github.com/JacobPEvans/nix-darwin/commit/94630a1a1d838628d8d1f37c504152ef8ca009b5))
* move Postman from nixpkgs to Homebrew cask ([#809](https://github.com/JacobPEvans/nix-darwin/issues/809)) ([35b28f9](https://github.com/JacobPEvans/nix-darwin/commit/35b28f90238f03a0f98894294393787a5c6d42b6))
* remove blanket auto-merge workflow ([#789](https://github.com/JacobPEvans/nix-darwin/issues/789)) ([618eca9](https://github.com/JacobPEvans/nix-darwin/commit/618eca9f4f85adea87e0cffd570c42213227fee8))
* remove unused lambda parameters flagged by deadnix ([#808](https://github.com/JacobPEvans/nix-darwin/issues/808)) ([862c660](https://github.com/JacobPEvans/nix-darwin/commit/862c66092e4f62680425866dcb979b5578e99f58))
* rename GH_APP_ID secret to GH_ACTION_JACOBPEVANS_APP_ID ([#814](https://github.com/JacobPEvans/nix-darwin/issues/814)) ([8be189b](https://github.com/JacobPEvans/nix-darwin/commit/8be189b02f82642a6f4f00612fab985411364d27))
* **renovate:** add shared preset, remove global automerge, fix deprecated matchers ([#796](https://github.com/JacobPEvans/nix-darwin/issues/796)) ([315907d](https://github.com/JacobPEvans/nix-darwin/commit/315907d3ec7a2d9a51902c29f9c92d0a8596b574))
* **renovate:** deduplicate config and guard git-refs major updates ([#797](https://github.com/JacobPEvans/nix-darwin/issues/797)) ([e5d6251](https://github.com/JacobPEvans/nix-darwin/commit/e5d625123a1bf198b8557daf30be7aa834a52dee))
* update ClaudeBar to v0.4.43 ([#818](https://github.com/JacobPEvans/nix-darwin/issues/818)) ([35b6dfa](https://github.com/JacobPEvans/nix-darwin/commit/35b6dfad18fcfa17e3d3fd5dec50d5c16fc616d7))
