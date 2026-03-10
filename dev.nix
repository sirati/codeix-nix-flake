{ pkgs, rustToolchain }:
pkgs.mkShell {
  name = "nix-rust-dev";

  packages = with pkgs; [
    # Rust toolchain (compiler, cargo, rust-analyzer, clippy, rustfmt)
    rustToolchain

    # Nix LSPs
    nil
    nixd

    # Nix formatter
    nixfmt

    # Build essentials
    pkg-config
    gcc

    # Useful Rust / dev tooling
    # cargo-edit
    # cargo-watch
  ];

  RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
}
