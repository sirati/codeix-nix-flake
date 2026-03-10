{ pkgs, rustToolchain }:
let
  makeApp = name: description: runtimeInputs: text:
    let
      script = pkgs.writeShellApplication { inherit name runtimeInputs text; };
    in
    { type = "app"; program = "${script}/bin/${name}"; meta = { inherit description; }; };

  cargoApp = name: description: cargoCmd:
    makeApp name description [ rustToolchain ] ''
      cargo ${cargoCmd} "$@"
    '';

  sitePrepText = ''
    mkdir -p site/static/schemas site/static/spec site/content/spec
    cp spec/*.schema.json site/static/schemas/
    cp spec/*.schema.json site/static/spec/
    cp spec/codeindex.md site/content/spec/_index.md
  '';
in
{
  # Default: check + test + build (mirrors `make all`)
  all = makeApp "all" "Run check, test, and build" [ rustToolchain ] ''
    cargo check
    cargo test
    cargo build --release
  '';

  # cargo build --release
  build = cargoApp "build" "Build the project in release mode" "build --release";

  # cargo run -- [ARGS...]  e.g. nix run .#run -- serve
  run = cargoApp "run" "Run the project (pass args after --)" "run --";

  # Fast compile check without codegen
  check = cargoApp "check" "Fast compile check without codegen" "check";

  # Run tests
  test = cargoApp "test" "Run the test suite" "test";

  # Clippy with -D warnings
  lint = makeApp "lint" "Run clippy with -D warnings" [ rustToolchain ] ''
    cargo clippy -- -D warnings "$@"
  '';

  # Format source
  fmt = cargoApp "fmt" "Format source with rustfmt" "fmt";

  # Format check (CI)
  "fmt-check" = makeApp "fmt-check" "Check formatting without writing changes" [ rustToolchain ] ''
    cargo fmt -- --check "$@"
  '';

  # Remove build artefacts
  clean = cargoApp "clean" "Remove build artefacts" "clean";

  # Prepare site assets (mirrors site-prep dependency)
  "site-prep" = makeApp "site-prep" "Copy spec assets into the site directory" [ ] sitePrepText;

  # Build the Zola site
  site = makeApp "site" "Build the Zola static site" [ pkgs.zola ] ''
    ${sitePrepText}
    cd site && zola build
  '';

  # Serve the Zola site locally
  "site-serve" = makeApp "site-serve" "Serve the Zola site locally" [ pkgs.zola ] ''
    ${sitePrepText}
    cd site && zola serve
  '';

  # Remove generated site assets
  "site-clean" = makeApp "site-clean" "Remove generated site assets" [ ] ''
    rm -rf site/public site/static/schemas site/static/spec site/content/spec/_index.md
  '';

  # Print benchmark usage (mirrors `make bench`)
  bench = makeApp "bench" "Print benchmark usage information" [ ] ''
    echo "Usage: nix run .#bench-speed | nix run .#bench-quality | nix run .#bench-value"
    echo "  bench-speed    - Quantitative indexing speed benchmark"
    echo "  bench-quality  - A/B: prod codeix vs dev codeix"
    echo "  bench-value    - A/B: codeix vs raw Claude"
  '';

  # Indexing speed benchmark (builds first, mirrors bench-speed: build)
  "bench-speed" = makeApp "bench-speed" "Quantitative indexing speed benchmark" [ rustToolchain pkgs.python3 ] ''
    cargo build --release
    python3 -m scripts.bench index-speed "$@"
  '';

  # Search quality A/B benchmark
  "bench-quality" = makeApp "bench-quality" "A/B search quality benchmark: prod vs dev codeix" [ rustToolchain pkgs.python3 ] ''
    cargo build --release
    python3 -m scripts.bench search-quality "$@"
  '';

  # Search value A/B benchmark
  "bench-value" = makeApp "bench-value" "A/B search value benchmark: codeix vs raw Claude" [ rustToolchain pkgs.python3 ] ''
    cargo build --release
    python3 -m scripts.bench search-value "$@"
  '';
}
