self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hare;
  glass = self.lib.glass;

  # Build a submodule whose options mirror the keys of the palette, so a
  # consumer can override single colours (e.g. theme.palette.accent) while
  # everything else keeps the glass default.
  paletteType = lib.types.submodule {
    options = builtins.mapAttrs (
      _: default:
      lib.mkOption {
        type = if builtins.isFloat default then lib.types.float else lib.types.str;
        inherit default;
      }
    ) glass;
  };

  configJson = pkgs.writeText "hare-config.json" (
    builtins.toJSON {
      theme = {
        inherit (cfg.theme) fonts palette;
      };
      bar = {
        inherit (cfg.bar) height style;
      };
    }
  );
in
{
  options.programs.hare = {
    enable = lib.mkEnableOption "the hare liquid-glass Quickshell shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The hare package to use.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run hare as a graphical-session systemd user service.";
    };

    theme = {
      palette = lib.mkOption {
        type = paletteType;
        default = { };
      };
      fonts = {
        sans = lib.mkOption {
          type = lib.types.str;
          default = "sans-serif";
        };
        mono = lib.mkOption {
          type = lib.types.str;
          default = "monospace";
        };
      };
    };

    bar = {
      height = lib.mkOption {
        type = lib.types.int;
        default = 36;
      };
      style = lib.mkOption {
        type = lib.types.enum [
          "floating"
          "full"
          "notched"
        ];
        default = "notched";
        description = "Bar style: floating (inset, rounded), full (edge-to-edge), or notched (edge-to-edge with concave bottom corners scooping into the screen).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."hare/config.json".source = configJson;

    systemd.user.services.hare = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "hare — liquid-glass Quickshell shell";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${cfg.package}/bin/hare";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
