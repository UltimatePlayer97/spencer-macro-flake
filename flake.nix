{
  description = "Spencer Macro Utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "3.3.1";
        tag = "V${version}";

        src = pkgs.fetchurl {
          url = "https://github.com/Spencer0187/Spencer-Macro-Utilities/releases/download/${tag}/Spencer-Macro-Utilities-${tag}-Linux-x86_64.AppImage";
          sha256 = "dJ1AvR5dwMk8svE0bJBEKV1+OK+sXrrWdTaPc6TZ2p0=";
        };

        appimageContents = pkgs.appimageTools.extract {
          pname = "suspend";
          inherit version src;
        };

        desktopItem = pkgs.makeDesktopItem {
          name = "suspend";
          desktopName = "Spencer Macro Utilities";
          comment = "An open source Roblox macro with many features.";
          exec = "suspend %u";
          icon = "suspend";
          categories = [ "Utility" ];
        };
      in
      {
        packages.default = pkgs.appimageTools.wrapType2 {
          pname = "suspend";
          inherit version src;


          extraPkgs = pkgs: [
            pkgs.libei
          ];

          extraInstallCommands = ''
            install -Dm644 ${desktopItem}/share/applications/suspend.desktop \
              $out/share/applications/suspend.desktop

            sed -i -E '/^Categories=/ s/([^;])$/\1;/' \
              $out/share/applications/suspend.desktop

            # icon: adjust path to whatever the AppImage actually ships
            icon=$(find ${appimageContents} -maxdepth 1 -name '*.png' | head -n1)
            if [ -n "$icon" ]; then
              install -Dm644 "$icon" $out/share/icons/hicolor/512x512/apps/suspend.png
            fi
          '';

          meta = with pkgs.lib; {
            description = "Spencer Macro Utilities";
            homepage = "https://spencermacro.vercel.app/";
            mainProgram = "suspend";
            platforms = [ "x86_64-linux" ];
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
