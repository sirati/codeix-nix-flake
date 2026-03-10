{
  description = "Nix flake providing a dev shell for Nix & Rust development and the codeix package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    let
      releaseFiles = builtins.readDir ./release-hashes;
      releases = builtins.listToAttrs (map
        (file: {
          name = builtins.substring 0 (builtins.stringLength file - 4) file;
          value = import ./release-hashes/${file};
        })
        (builtins.filter
          (f: builtins.match ".*\\.nix" f != null)
          (builtins.attrNames releaseFiles)));

      defaultRelease = releases."v0.5.0";

      mkCodeix = { pkgs, release ? defaultRelease, langs ? null }:
        import ./package.nix { inherit pkgs release langs; };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };

        versionedPackages = pkgs.lib.mapAttrs
          (_: release: mkCodeix { inherit pkgs release; })
          releases;

        defaultPackage = versionedPackages."v0.5.0";
      in
      {
        packages = versionedPackages // {
          codeix = defaultPackage;
          default = defaultPackage;
        };

        apps = import ./makefile.nix { inherit pkgs rustToolchain; };

        devShells.default = import ./dev.nix { inherit pkgs rustToolchain; };
      }
    ) // {
      overlays = {
        default = final: _prev: {
          codeix = mkCodeix { pkgs = final; };
        };
      };

      lib = {
        inherit mkCodeix releases defaultRelease;
        availableLangs = [
          "python" "rust" "javascript" "typescript"
          "go" "java" "c" "cpp" "ruby" "csharp" "markdown"
        ];
      };
    };
}
