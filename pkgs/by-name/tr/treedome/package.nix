{
  lib,
  cargo-tauri,
  dbus,
  fetchgit,
  fetchYarnDeps,
  freetype,
  gsettings-desktop-schemas,
  stdenv,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  openssl,
  pkg-config,
  rustPlatform,
  webkitgtk_4_1,
  libayatana-appindicator,
  wrapGAppsHook3,
  sqlite,
}:

let
  pname = "treedome";
  version = "0.5.3";

  src = fetchgit {
    url = "https://codeberg.org/solver-orgz/treedome";
    rev = version;
    hash = "sha256-83H2j6yk/MOdIVHTRZkpD1Q9GS21kzW2myTVvqsBz7M=";
    fetchLFS = true;
  };

  frontend-build = stdenv.mkDerivation (finalAttrs: {
    pname = "treedome-ui";
    inherit version src;

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-in1A1XcfZK5F/EV5CYgfqig+8vKsxd6XhzfSv7Z0nNQ=";
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/dist
      cp -r dist/** $out/dist

      runHook postInstall
    '';
  });
in
rustPlatform.buildRustPackage {
  inherit version pname src;
  sourceRoot = "${src.name}/src-tauri";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "fix-path-env-0.0.0" = "sha256-ewE3CwqLC8dvi94UrQsWbp0mjmrzEJIGPDYtdmQ/sGs=";
    };
  };

  preConfigure = ''
    mkdir -p dist
    cp -R ${frontend-build}/dist/** dist
  '';

  # copy the frontend static resources to final build directory
  # Also modify tauri.conf.json so that it expects the resources at the new location
  postPatch = ''
    substituteInPlace ./tauri.conf.json \
      --replace-fail '"frontendDist": "../dist",' '"frontendDist": "dist",' \
      --replace-fail '"beforeBuildCommand": "yarn run build",' '"beforeBuildCommand": "",'

    substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
      --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    dbus
    openssl
    freetype
    webkitgtk_4_1
    libayatana-appindicator
    gsettings-desktop-schemas
    sqlite
  ];

  env = {
    VERGEN_GIT_DESCRIBE = version;
  };

  # WEBKIT_DISABLE_COMPOSITING_MODE essential in NVIDIA + compositor https://github.com/NixOS/nixpkgs/issues/212064#issuecomment-1400202079
  postFixup = ''
    wrapProgram "$out/bin/treedome" \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1
  '';

  meta = with lib; {
    description = "Local-first, encrypted, note taking application organized in tree-like structures";
    homepage = " https://codeberg.org/solver-orgz/treedome";
    license = licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "treedome";
    maintainers = with maintainers; [ tengkuizdihar ];
    changelog = "https://codeberg.org/solver-orgz/treedome/releases/tag/${version}";
  };
}
