# Plan: bootstrap nix-thinkorswim package repository

## Spec

Create a new standalone Nix flake repository `nix-thinkorswim` modeled after existing package repos in this workspace, with Linux/NixOS-friendly thinkorswim install and launch behavior using Zulu OpenJDK 21.

## Constraints

- Keep package output usable on NixOS (`x86_64-linux`).
- Respect thinkorswim's writable/self-updating runtime model.
- Keep repository scaffold consistent with sibling repos (`flake.nix`, `package.nix`, `justfile`, CI).

## Success Criteria

- `nix-thinkorswim/` contains a flake package and runnable app output.
- Launcher uses `zulu21`.
- First run installs into user-writable location and then launches.
- Lint/build checks pass locally.
- Repo includes clear usage documentation.

## Task Checklist

- [x] Create repository scaffold and metadata files.
- [x] Implement package and runtime launcher wrapper.
- [x] Add CI + local `just` workflows.
- [x] Document usage and runtime behavior in README.
- [x] Run local validation (`just check`, `just build`, smoke run).
- [x] (Optional next step) wire package into `nixos-config/modules/nixos/packages.nix`.

## Follow-up: align CI/linting with riva

- [x] Compare `~/Projects/riva/.github/workflows/ci.yml` and related `just`/pre-commit hooks.
- [x] Add `precommit-run` support to `nix-thinkorswim` justfile.
- [x] Update `nix-thinkorswim` GitHub Actions CI to run matching linting/check steps.
- [x] Re-run local verification for updated CI/linting commands.
