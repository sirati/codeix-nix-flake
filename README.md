# codeix-nix-flake

Nix flake packaging for [codeix](https://github.com/montanetech/codeix) — fast semantic code search for AI agents.

## Quick start

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    codeix-nix-flake.url = "github:sirati/codeix-nix-flake";
  };

  outputs = { nixpkgs, codeix-nix-flake, ... }: {
    # Default: latest release, all languages
    packages.x86_64-linux.codeix =
      codeix-nix-flake.lib.mkCodeix { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
  };
}
```

## Selecting languages

By default all 11 tree-sitter grammars are compiled in (matching the upstream Cargo defaults).
Pass `langs` to restrict to only the languages you need — this speeds up the build and shrinks the binary.

Available language names:

| Name         |
|--------------|
| `python`     |
| `rust`       |
| `javascript` |
| `typescript` |
| `go`         |
| `java`       |
| `c`          |
| `cpp`        |
| `ruby`       |
| `csharp`     |
| `markdown`   |

```nix
codeix-nix-flake.lib.mkCodeix {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  langs = [ "python" "rust" "typescript" ];
}
```

Omitting `langs` (or passing `null`) builds with all languages.

## Selecting a version

The flake ships release specs for the following versions:

| Attribute  | Version |
|------------|---------|
| `"v0.5.0"` | 0.5.0   |
| `"v0.4.1"` | 0.4.1   |
| `"v0.4.0"` | 0.4.0   |
| `"v0.3.0"` | 0.3.0   |

Pass a release from `lib.releases` to target a specific version:

```nix
codeix-nix-flake.lib.mkCodeix {
  pkgs  = nixpkgs.legacyPackages.x86_64-linux;
  release = codeix-nix-flake.lib.releases."v0.4.1";
}
```

Combining version and language selection:

```nix
codeix-nix-flake.lib.mkCodeix {
  pkgs    = nixpkgs.legacyPackages.x86_64-linux;
  release = codeix-nix-flake.lib.releases."v0.4.1";
  langs   = [ "python" "rust" "markdown" ];
}
```

## Dev shell

The flake provides a dev shell with a full Nix & Rust toolchain:

```
nix develop
```

Included tools:

- `rustc`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`
- `nil`, `nixd` (Nix LSPs)
- `nixfmt`
- `cargo-edit`, `cargo-watch`, `cargo-nextest`

## Makefile targets

All upstream Makefile targets are available via `nix run`:

```
nix run .#build
nix run .#check
nix run .#test
nix run .#lint
nix run .#fmt
nix run .#fmt-check
nix run .#clean
nix run .#run -- serve        # extra args passed through after --
nix run .#site
nix run .#site-serve
nix run .#site-clean
nix run .#bench-speed
nix run .#bench-quality
nix run .#bench-value
```

## Adding a new release

1. Look up the commit SHA for the tag on GitHub.
2. Prefetch the source hash:
   ```
   nix-prefetch-url --unpack https://github.com/montanetech/codeix/archive/<rev>.tar.gz
   nix hash convert --hash-algo sha256 --from nix32 <result>
   ```
3. Create `release-hashes/vX.Y.Z.nix` with a fake `cargoHash`:
   ```nix
   {
     version = "X.Y.Z";
     rev     = "<commit-sha>";
     hash    = "<source-hash>";
     cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
   }
   ```
4. Run `nix build '.#packages.x86_64-linux."vX.Y.Z"'` — the error output contains the real `cargoHash`.
5. Replace the fake hash with the real one.

The new version is picked up automatically — no changes to `flake.nix` required.