# nix-thinkorswim

[![CI](https://github.com/rbright/nix-thinkorswim/actions/workflows/ci.yml/badge.svg)](https://github.com/rbright/nix-thinkorswim/actions/workflows/ci.yml)

Nix package for Charles Schwab thinkorswim.

## What this repo provides

- Nix package: `thinkorswim` (binary: `thinkorswim`)
- Nix app output: `.#thinkorswim`
- Wrapper that uses `zulu21` (OpenJDK 21)
- First-run unattended installer flow into user-writable storage
- Local quality gate (`just`) and GitHub Actions CI

## How installation works

thinkorswim is self-updating and expects writable application files.
Running directly from `/nix/store` does not work well for that model.

This package therefore:

1. Ships the official Schwab Linux installer script in the Nix store.
2. On first launch, installs thinkorswim into:
   - `$THINKORSWIM_HOME` when set, else
   - `$XDG_DATA_HOME/thinkorswim`, else
   - `~/.local/share/thinkorswim`
3. Launches thinkorswim with `INSTALL4J_JAVA_HOME_OVERRIDE` pointing at `zulu21`.

## Quickstart

```sh
# list commands
just --list

# full local validation gate
just check

# build
just build

# run (first run installs into your user data dir)
just run
```

## Build and run directly with Nix

```sh
nix build -L 'path:.#thinkorswim'
nix run 'path:.#thinkorswim'
```

## Runtime knobs

- `THINKORSWIM_HOME`: override install location (must be writable)
- `THINKORSWIM_FORCE_REINSTALL=1`: remove existing install before launching
- `THINKORSWIM_PATCH_LAUNCHER_JAVA=0`: disable launcher-script Java pinning (debug/rollback knob)

Example:

```sh
THINKORSWIM_HOME="$HOME/.local/share/thinkorswim" THINKORSWIM_FORCE_REINSTALL=1 nix run 'path:.#thinkorswim'
```

## Troubleshooting

If you see:

- `Zulu OpenJDK 21.0.5 is required to start the application`
- or thinkorswim appears stuck on `Installing updates...`

you are likely launching a legacy installer-created script/desktop entry (for example
`~/Desktop/thinkorswim.desktop`) that bypasses the Nix wrapper and falls back to
an older system Java.

Use the packaged launcher instead:

```sh
thinkorswim
```

and remove/ignore old installer desktop launchers. This package does not install its own
`.desktop` launcher entry.

## Notes

- License: proprietary/unfree. You must comply with Schwab's terms.
- Platform: `x86_64-linux`.
- The application updates itself independently of this package repository.

## Use from another flake

```nix
{
  inputs.nixThinkorswim.url = "github:rbright/nix-thinkorswim";

  outputs = { self, nixpkgs, nixThinkorswim, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            nixThinkorswim.packages.${pkgs.system}.thinkorswim
          ];
        })
      ];
    };
  };
}
```
