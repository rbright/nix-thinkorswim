{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  bash,
  coreutils,
  findutils,
  gawk,
  gnugrep,
  gnused,
  gnutar,
  gzip,
  zulu21,
  alsa-lib,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libxkbcommon,
  nspr,
  nss,
  pango,
  libx11,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxinerama,
  libxrandr,
  libxrender,
  libxtst,
  libxcb,
  libxshmfence,
}:
stdenvNoCC.mkDerivation {
  pname = "thinkorswim";
  version = "1984.1.7";

  src = fetchurl {
    url = "https://tosmediaserver.schwab.com/installer/InstFiles/thinkorswim_installer.sh";
    hash = "sha256-ZvZ3dJoUdu8wFu0avKeRipO2lIZ0yTmh8Tl93fJ0uW0=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "thinkorswim";
      desktopName = "thinkorswim";
      genericName = "Trading Platform";
      comment = "Launch Charles Schwab thinkorswim";
      exec = "thinkorswim";
      terminal = false;
      categories = [
        "Office"
        "Finance"
      ];
      startupWMClass = "thinkorswim";
    })
  ];

  dontUnpack = true;

  installPhase =
    let
      installerRuntimeTools = [
        bash
        coreutils
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        gzip
      ];

      runtimeLibraries = [
        alsa-lib
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libdrm
        libgbm
        libglvnd
        libxkbcommon
        nspr
        nss
        pango
        stdenv.cc.cc.lib
        libx11
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxinerama
        libxrandr
        libxrender
        libxtst
        libxcb
        libxshmfence
      ];
    in
    ''
      runHook preInstall

      install -Dm755 "$src" "$out/libexec/thinkorswim/thinkorswim_installer.sh"
      install -Dm755 ${./scripts/run-thinkorswim.sh} "$out/libexec/thinkorswim/run-thinkorswim.sh"

      makeWrapper "$out/libexec/thinkorswim/run-thinkorswim.sh" "$out/bin/thinkorswim" \
        --prefix PATH : "${lib.makeBinPath installerRuntimeTools}" \
        --set THINKORSWIM_INSTALLER "$out/libexec/thinkorswim/thinkorswim_installer.sh" \
        --set THINKORSWIM_JAVA_HOME "${zulu21}" \
        --set THINKORSWIM_RUNTIME_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibraries}"

      runHook postInstall
    '';

  meta = {
    description = "thinkorswim desktop trading platform launcher for NixOS";
    homepage = "https://www.schwab.com/trading/thinkorswim";
    license = lib.licenses.unfree;
    mainProgram = "thinkorswim";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
