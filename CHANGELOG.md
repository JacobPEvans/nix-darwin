# Changelog

## [1.13.6](https://github.com/JacobPEvans/nix-darwin/compare/v1.13.5...v1.13.6) (2026-03-22)


### Bug Fixes

* **flake-rebuild:** clarify command must always execute the rebuild ([#893](https://github.com/JacobPEvans/nix-darwin/issues/893)) ([c0c2960](https://github.com/JacobPEvans/nix-darwin/commit/c0c2960115222eb6522b6f8cd4f2737666d86ced))

## [1.13.5](https://github.com/JacobPEvans/nix-darwin/compare/v1.13.4...v1.13.5) (2026-03-21)


### Bug Fixes

* consolidate file-size config into .file-size.yml with shared defaults ([#889](https://github.com/JacobPEvans/nix-darwin/issues/889)) ([a141129](https://github.com/JacobPEvans/nix-darwin/commit/a14112941c77b33bab77abb00d72edce7c806f42))

## [1.13.4](https://github.com/JacobPEvans/nix-darwin/compare/v1.13.3...v1.13.4) (2026-03-21)


### Bug Fixes

* consolidate Renovate config and remove broken postUpgradeTasks ([#886](https://github.com/JacobPEvans/nix-darwin/issues/886)) ([d0fe728](https://github.com/JacobPEvans/nix-darwin/commit/d0fe728e278c3b5594e539b38ea35e1f4c327f0c))
* exempt CHANGELOG.md from file size limit ([#887](https://github.com/JacobPEvans/nix-darwin/issues/887)) ([c071d53](https://github.com/JacobPEvans/nix-darwin/commit/c071d53cf3c35d7b8bce874bff2cc21e1ccb5a43))
* update flake inputs after nix-ai and nix-home cleanup PRs ([#882](https://github.com/JacobPEvans/nix-darwin/issues/882)) ([0a05872](https://github.com/JacobPEvans/nix-darwin/commit/0a058724ace7d6f192702aa90d99c26bb1f44832))
* update nix-ai input (v0.2.6 CLI flags + checks split) ([#885](https://github.com/JacobPEvans/nix-darwin/issues/885)) ([7e19da6](https://github.com/JacobPEvans/nix-darwin/commit/7e19da6d768fe680957c5ba15940a82e98c0081a))

## [1.13.3](https://github.com/JacobPEvans/nix-darwin/compare/v1.13.2...v1.13.3) (2026-03-20)


### Bug Fixes

* remove nixpkgs-unstable overlay ([#879](https://github.com/JacobPEvans/nix-darwin/issues/879)) ([a870f35](https://github.com/JacobPEvans/nix-darwin/commit/a870f356a4d6f6a55043c2f021593151647024a4))
* update CLAUDE.md to reference three companion repos (quartet) ([#881](https://github.com/JacobPEvans/nix-darwin/issues/881)) ([82ca482](https://github.com/JacobPEvans/nix-darwin/commit/82ca482825280f53b03c007bff894d3260695076))

## [1.13.2](https://github.com/JacobPEvans/nix-darwin/compare/v1.13.1...v1.13.2) (2026-03-20)


### Bug Fixes

* bump stateVersion to 25.11 with drift assertion ([#877](https://github.com/JacobPEvans/nix-darwin/issues/877)) ([887a41a](https://github.com/JacobPEvans/nix-darwin/commit/887a41acd16da94220c9cfbb1b8bd5bae0ebf3fc))

## [1.13.1](https://github.com/JacobPEvans/nix-darwin/compare/v1.13.0...v1.13.1) (2026-03-20)


### Bug Fixes

* bump homeManagerStateVersion to 25.11 ([#873](https://github.com/JacobPEvans/nix-darwin/issues/873)) ([12fd1ee](https://github.com/JacobPEvans/nix-darwin/commit/12fd1ee4c2dd9f69429c50a80986b6a152aedc83))
* remove Ollama from system packages and disable volume ([#875](https://github.com/JacobPEvans/nix-darwin/issues/875)) ([58ef9f9](https://github.com/JacobPEvans/nix-darwin/commit/58ef9f9b693ab7193e7066ec1bbe5f420837ae47))

## [1.13.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.12.2...v1.13.0) (2026-03-20)


### Features

* add Cribl Edge nix-darwin module ([#871](https://github.com/JacobPEvans/nix-darwin/issues/871)) ([3d1758b](https://github.com/JacobPEvans/nix-darwin/commit/3d1758b4f0dc683032dcde0559f4fa9c4f796726))

## [1.12.2](https://github.com/JacobPEvans/nix-darwin/compare/v1.12.1...v1.12.2) (2026-03-19)


### Bug Fixes

* update nix-ai (MLX port 11435→11436, screenpipe conflict) ([#869](https://github.com/JacobPEvans/nix-darwin/issues/869)) ([d399876](https://github.com/JacobPEvans/nix-darwin/commit/d39987629c25af1c7f02425e3aa56d13b6564f75))

## [1.12.1](https://github.com/JacobPEvans/nix-darwin/compare/v1.12.0...v1.12.1) (2026-03-19)


### Bug Fixes

* add release-please config for manifest mode ([84ed18b](https://github.com/JacobPEvans/nix-darwin/commit/84ed18b8c92816da83577e3441da52e47f4fd024))
* sync release-please permissions and VERSION ([ba0eb02](https://github.com/JacobPEvans/nix-darwin/commit/ba0eb02830635cbc36ab81f4ee1c15c556e96dd0))
* update nix-ai flake input to latest ([#860](https://github.com/JacobPEvans/nix-darwin/issues/860)) ([10c6032](https://github.com/JacobPEvans/nix-darwin/commit/10c6032b08cfa47d4dd3f926e173f2df38013b65))

## [1.12.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.11.0...v1.12.0) (2026-03-17)


### Bug Fixes

* **darwin:** remove Paw defaults write (sandboxed container app) ([#856](https://github.com/JacobPEvans/nix-darwin/issues/856)) ([3abb0fb](https://github.com/JacobPEvans/nix-darwin/commit/3abb0fbb58e4a855acc305446a8181d258c7fb05))

## [1.11.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.10.0...v1.11.0) (2026-03-16)


### Bug Fixes

* **homebrew:** add greedy flag to microsoft-teams cask ([#853](https://github.com/JacobPEvans/nix-darwin/issues/853)) ([3191d05](https://github.com/JacobPEvans/nix-darwin/commit/3191d0535fbf9e61ae7e3ecdb4b82bbfd6716b7d))

## [1.10.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.9.0...v1.10.0) (2026-03-15)


### Bug Fixes

* **ci:** add pull-requests: write for release-please auto-approval ([#850](https://github.com/JacobPEvans/nix-darwin/issues/850)) ([b561b18](https://github.com/JacobPEvans/nix-darwin/commit/b561b18c56b06549fe10dd18a757db6e72b1174e))

## [1.9.0](https://github.com/JacobPEvans/nix-darwin/compare/v1.8.0...v1.9.0) (2026-03-15)


### Bug Fixes

* **ci:** add pull-requests: write for release-please auto-approval ([#848](https://github.com/JacobPEvans/nix-darwin/issues/848)) ([b9cb5a8](https://github.com/JacobPEvans/nix-darwin/commit/b9cb5a83b6aca2f7536cfd5ead8837e57f25c7b4))

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
