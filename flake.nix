{
  description = "hare — a neutral liquid-glass Quickshell desktop shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      # The default glass palette (dark). Plain data so consumers can reuse
      # the exact colours for other surfaces (rofi, lock screens, etc.).
      lib.glass = import ./nix/palette.nix;

      homeManagerModules.default = import ./nix/hm-module.nix self;
      homeManagerModules.hare = self.homeManagerModules.default;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.callPackage ./nix/package.nix { };
        packages.hare = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            quickshell
            qt6.qtdeclarative
          ];

          # qmlls (launched by the editor with -E) reads QML_IMPORT_PATH to
          # resolve imports. On Nix the modules live under lib/qt-6/qml, which
          # qmlls does NOT auto-discover, so we list both: qtdeclarative for
          # QtQuick/QtQml and quickshell for Quickshell.* .
          QML_IMPORT_PATH = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
            pkgs.qt6.qtdeclarative
            pkgs.quickshell
          ];
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
