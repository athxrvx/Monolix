{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  fish,
  ddcutil,
  brightnessctl,
  networkmanager,
  lm_sensors,
  swappy,
  wl-clipboard,
  libqalculate,
  fftw,
  bash,
  ffmpeg,

  material-symbols,
  rubik,
  nerd-fonts,
  qt6,
  quickshell,
  aubio,
  libcava,
  pipewire,
  xkeyboard-config,
  cmake,
  ninja,
  pkg-config,
  debug ? false,
  extraRuntimeDeps ? [],
  ...
}: let
  version = "1.0.0";

  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      networkmanager
      lm_sensors
      swappy
      wl-clipboard
      libqalculate
      bash
      ffmpeg
    ]
    ++ extraRuntimeDeps;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols rubik nerd-fonts.jetbrains-mono];
  };

  cmakeVersionFlags = [
    (lib.cmakeFeature "VERSION" version)
    (lib.cmakeFeature "GIT_REVISION" rev)
    (lib.cmakeFeature "DISTRIBUTOR" "nix-flake")
  ];

  extras = stdenv.mkDerivation {
    name = "monolix-extras${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../extras;
    };

    nativeBuildInputs = [cmake ninja];

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "extras")
        (lib.cmakeFeature "INSTALL_LIBDIR" "${placeholder "out"}/lib")
      ]
      ++ cmakeVersionFlags;
  };

  plugin = stdenv.mkDerivation {
    name = "monolix-qml-plugin${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../plugin;
    };

    nativeBuildInputs = [cmake ninja pkg-config];
    buildInputs = [qt6.qtbase qt6.qtdeclarative qt6.qt5compat fftw qt6.qtmultimedia libqalculate pipewire aubio libcava];

    dontWrapQtApps = true;
    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "plugin")
        (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
      ]
      ++ cmakeVersionFlags;
  };
in
  stdenv.mkDerivation {
    inherit version;
    pname = "monolix${lib.optionalString debug "-debug"}";
    src = ./..;

    nativeBuildInputs = [cmake ninja makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [quickshell extras plugin xkeyboard-config qt6.qtbase qt6.qtmultimedia];
    propagatedBuildInputs = runtimeDeps;

    cmakeBuildType =
      if debug
      then "Debug"
      else "RelWithDebInfo";
    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "shell")
        (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/monolix")
      ]
      ++ cmakeVersionFlags;

    dontStrip = debug;

    prePatch = ''
      substituteInPlace assets/pam.d/fprint \
        --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so
      substituteInPlace shell.qml \
        --replace-fail 'ShellRoot {' 'ShellRoot {  settings.watchFiles: false'
    '';

    postInstall = ''
      makeWrapper ${quickshell}/bin/qs $out/bin/monolix \
      	--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
        --prefix QML2_IMPORT_PATH : "${lib.makeSearchPath qt6.qtbase.qtQmlPrefix [qt6.qtdeclarative qt6.qt5compat qt6.qtmultimedia plugin]}" \
      	--set FONTCONFIG_FILE "${fontconfig}" \
      	--set MONOLIX_LIB_DIR ${extras}/lib \
        --set MONOLIX_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
      	--add-flags "-p $out/share/monolix"

      mkdir -p $out/lib
      ln -s ${extras}/lib/* $out/lib/


    '';

    passthru = {
      inherit plugin extras;
    };

    meta = {
      description = "Monolix desktop shell for Niri";
      homepage = "https://github.com/athxrvx/athena";
      license = lib.licenses.gpl3Only;
      mainProgram = "monolix";
    };
  }
