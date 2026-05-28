# hare

A neutral **liquid-glass** desktop shell built on [Quickshell](https://quickshell.org).
Translucent grayscale panels with compositor blur that read neutrally over any wallpaper —
and an **adaptive tone** that flips between dark and light glass based on the wallpaper's
luminance.

Currently ships a top **bar**: workspaces, system tray, audio / microphone / keyboard-layout
status, a clock, and a power button.

> Status: early. The bar works; launcher / session / OSDs are not part of hare yet.

## Install (Nix flake + home-manager)

```nix
# flake.nix
{
  inputs.hare.url = "github:peteyycz/hare";
  # ...
}
```

```nix
# home-manager configuration
{ inputs, ... }:
{
  imports = [ inputs.hare.homeManagerModules.default ];

  programs.hare = {
    enable = true;
    wallpaper = "${config.home.homeDirectory}/.local/share/backgrounds/default.jpg";
    theme.fonts = {
      sans = "Inter";
      mono = "JetBrainsMono Nerd Font";
    };
  };
}
```

`hare` runs as a `graphical-session` systemd user service. It does **not** set your wallpaper,
manage idle/lock, or bind keys — it only renders the bar and samples the wallpaper for tone.

### Compositor setup (Hyprland)

The bar uses the layer-shell namespace `hare`. To get the frosted-glass look, blur that layer:

```
layerrule = blur, hare
layerrule = ignorealpha 0.5, hare
```

The keyboard-layout indicator and tray rely on a running Wayland compositor with
`hyprctl` available (Hyprland). Other wlroots compositors render the bar but won't populate
the keyboard layout.

## Options (`programs.hare`)

| Option | Default | Description |
| --- | --- | --- |
| `enable` | `false` | Enable the shell. |
| `package` | this flake's package | The hare package. |
| `systemd.enable` | `true` | Run as a graphical-session user service. |
| `wallpaper` | `null` | Image sampled for adaptive tone (not set by hare). |
| `theme.mode` | `"adaptive"` | `adaptive` \| `dark` \| `light`. |
| `theme.palette.{dark,light}.*` | glass defaults | Per-colour overrides (`bg`, `fg`, `accent`, …). |
| `theme.fonts.{sans,mono}` | system defaults | Font families. |
| `bar.height` | `36` | Bar height in px. |
| `bar.entries` | `[workspaces spacer tray statusIcons clock power]` | Ordered entries; `spacer` splits left/right. |
| `bar.status.{showAudio,showMicrophone,showKbLayout}` | `true` | Status toggles. |

The default palette is also exported as plain data at `hare.lib.glass = { dark = {…}; light = {…}; }`
so you can reuse the exact colours for other surfaces (rofi, lock screen, polkit, …).

## Development

```sh
nix develop          # quickshell + tools
quickshell --path ./shell    # run the shell against the working tree (needs a Wayland session)
nix run .            # run the built package
./shell  # config layout: shell.qml + Theme.qml singleton + per-widget .qml files
```

Runtime config is read from `$XDG_CONFIG_HOME/hare/config.json` (written by the home-manager
module) and the live tone from `$XDG_STATE_HOME/hare/tone` (written by `hare-tone <image>`).

## License

MIT
