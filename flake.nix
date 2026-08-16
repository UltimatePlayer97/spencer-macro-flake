{
  description = "Spencer Macro Utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        runtimeLibs = with pkgs; [
          stdenv.cc.cc.lib
          alsa-lib
          pulseaudio
          libjack2
          sndio
          libX11
          libXext
          libXrandr
          libXcursor
          libXfixes
          libXi
          libXScrnSaver
          libXtst
          libxkbcommon
          libdrm
          libxcb-util
          libxcb
          mesa
          dbus
          ibus
          udev
          libthai
          fribidi
          libglvnd
          libgbm
        ];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "suspend";
          version = "3.2.1";

          src = pkgs.fetchFromGitHub {
            owner = "Spencer0187";
            repo = "Spencer-Macro-Utilities";
	    rev = "f5d807034719741dcbe809e11c2b43ec95691a23";
            sha256 = "sha256-kGYuu4+DKN/F1+PR9y+ppKWYoP75ViYVLIfB5+iQl+I=";
          };

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
            go
            patchelf
          ];

          buildInputs = runtimeLibs;

          HOME = "/tmp";
          GOCACHE = "/tmp/go-cache";

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DSMU_BUNDLE_SDL3=ON"
            "-DSMU_LINK_SDL3_STATIC=OFF"
          ];

          buildPhase = ''
            runHook preBuild

            cmake --build . --target package-linux-dir --parallel $NIX_BUILD_CORES

            echo "Building nethelper (Go)..."

            mkdir -p "$GOCACHE"

            cd "$src/platform/linux/nethelper"
            GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build \
              -o "$TMPDIR/nethelper" \
              .
            cd -

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            local pkgDir="SpencerMacroUtilities"
            local runtimeLibPath="${pkgs.lib.makeLibraryPath runtimeLibs}"

            mkdir -p "$out/bin" "$out/share/suspend"

            install -m755 "$pkgDir/suspend" "$out/share/suspend/suspend"

            patchelf --remove-rpath "$out/share/suspend/suspend"

            patchelf --set-rpath \
              "$runtimeLibPath:$out/share/suspend/lib" \
              "$out/share/suspend/suspend"

            install -m755 "$TMPDIR/nethelper" "$out/share/suspend/nethelper"

            cp -r "$pkgDir/assets" "$out/share/suspend/assets"

            if [ -d "$pkgDir/lib" ]; then
              cp -r "$pkgDir/lib" "$out/share/suspend/lib"
            fi

            if [ -f "$pkgDir/LINUX_SETUP.md" ]; then
              cp "$pkgDir/LINUX_SETUP.md" "$out/share/suspend/LINUX_SETUP.md"
            fi

            if [ -d "$pkgDir/scripts" ]; then
              cp -r "$pkgDir/scripts" "$out/share/suspend/scripts"
            fi

            cat > "$out/bin/suspend" << 'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

NETHELPER_TMP="/tmp/nethelper-$(id -u)"

if ! pgrep -f "$NETHELPER_TMP" >/dev/null 2>&1; then
  rm -f "$NETHELPER_TMP"
  cp "@out@/share/suspend/nethelper" "$NETHELPER_TMP"
  chmod +x "$NETHELPER_TMP"
  pkexec "$NETHELPER_TMP" &
fi

export LD_LIBRARY_PATH="@runtimeLibPath@:@out@/share/suspend/lib"
cd "@out@/share/suspend"
exec "@out@/share/suspend/suspend" "$@"
LAUNCHER

            substituteInPlace "$out/bin/suspend" \
              --replace "@out@" "$out" \
              --replace "@runtimeLibPath@" "$runtimeLibPath"

            chmod 755 "$out/bin/suspend"

            mkdir -p \
              "$out/share/pixmaps" \
              "$out/share/applications"

            cp "$src/public/favicon.ico" \
              "$out/share/pixmaps/suspend.ico"

            cat > "$out/share/applications/suspend.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Spencer Macro Utilities
Exec=$out/bin/suspend %u
Icon=$out/share/pixmaps/suspend.ico
Comment=Launch Spencer Macro Utilities
Categories=Utility;
Terminal=false
EOF

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Spencer Macro Utilities";
            mainProgram = "suspend";
            platforms = platforms.linux;
            license = licenses.gpl3Only;
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      })
    // {
      nixosModules.default = import ./module.nix;
    };
}
