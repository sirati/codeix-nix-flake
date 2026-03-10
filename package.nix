{ pkgs, release, langs ? null }:
let
  allLangs = [
    "python" "rust" "javascript" "typescript"
    "go" "java" "c" "cpp" "ruby" "csharp" "markdown"
  ];

  # Short names only (e.g. "rust") — always prefixed to cargo feature names
  toFeature = lang: "lang-${lang}";

  # null  → use Cargo default features (all langs)
  # [..] → disable defaults, enable only the listed langs
  buildNoDefaultFeatures = langs != null;
  buildFeatures = if langs != null then map toFeature langs else [ ];
in
pkgs.rustPlatform.buildRustPackage {
  pname = "codeix";
  inherit (release) version;

  src = pkgs.fetchFromGitHub {
    owner = "montanetech";
    repo = "codeix";
    inherit (release) rev hash;
  };

  inherit (release) cargoHash;
  inherit buildNoDefaultFeatures buildFeatures;

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; pkgs.lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  meta = with pkgs.lib; {
    description = "Fast semantic code search for AI agents";
    homepage = "https://codeix.dev";
    license = with licenses; [ mit asl20 ];
    mainProgram = "codeix";
    passthru.availableLangs = allLangs;
  };
}
