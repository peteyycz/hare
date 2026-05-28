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

  # Build a submodule whose options mirror the keys of a palette tone, so a
  # consumer can override single colours (e.g. theme.palette.dark.accent) while
  # everything else keeps the glass default.
  toneType =
    defaults:
    lib.types.submodule {
      options = builtins.mapAttrs (
        _: default:
        lib.mkOption {
          type = if builtins.isFloat default then lib.types.float else lib.types.str;
          inherit default;
        }
      ) defaults;
    };

  configJson = pkgs.writeText "hare-config.json" (
    builtins.toJSON {
      theme = {
        inherit (cfg.theme) mode fonts;
        palette = cfg.theme.palette;
      };
      bar = {
        inherit (cfg.bar) height entries status;
      };
      wallpaper = cfg.wallpaper;
    }
  );

  adaptiveTone = cfg.theme.mode == "adaptive" && cfg.wallpaper != null;
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

    wallpaper = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
      default = null;
      description = "Image sampled for adaptive tone. hare does not set the wallpaper itself.";
    };

    theme = {
      mode = lib.mkOption {
        type = lib.types.enum [
          "adaptive"
          "dark"
          "light"
        ];
        default = "adaptive";
        description = "Glass tone. 'adaptive' picks dark/light from the wallpaper's luminance.";
      };
      palette = {
        dark = lib.mkOption {
          type = toneType glass.dark;
          default = { };
        };
        light = lib.mkOption {
          type = toneType glass.light;
          default = { };
        };
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
      entries = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "workspaces"
            "spacer"
            "tray"
            "statusIcons"
            "clock"
            "power"
          ]
        );
        default = [
          "workspaces"
          "spacer"
          "tray"
          "statusIcons"
          "clock"
          "power"
        ];
        description = "Ordered bar entries. 'spacer' is a stretch that splits left/right.";
      };
      status = {
        showAudio = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        showMicrophone = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        showKbLayout = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
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
      }
      // lib.optionalAttrs adaptiveTone {
        ExecStartPre = "${cfg.package}/bin/hare-tone ${toString cfg.wallpaper}";
      };
    };
  };
}
