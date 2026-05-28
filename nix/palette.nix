# macOS "Liquid Glass" tokens (dark + light). Translucent grayscale surfaces
# with a bright top specular highlight, meant to sit over a wallpaper with
# compositor blur behind them. Colours are hex without '#'; *Alpha are 0..1.
#
# Legacy keys (bg, surface, fg, subtle, accent, error, border, bgAlpha,
# borderAlpha) are kept so other surfaces (rofi, polkit, hyprlock) can read a
# solid value; the bar additionally uses ink + fill/hairline/hi bases + alphas.
{
  dark = {
    bg = "18181c"; # glass tint base
    bgAlpha = 0.46; # glass translucency
    surface = "27272a"; # solid nested fill (overlays)
    ink = "ffffff"; # base for text (alpha applied per role)
    fg = "f4f5f7"; # solid text (overlays)
    subtle = "a1a1aa"; # solid dim text (overlays)
    fillBase = "ffffff";
    fillAlpha = 0.08;
    fillStrongAlpha = 0.15;
    hairlineBase = "ffffff";
    hairlineAlpha = 0.10;
    border = "ffffff";
    borderAlpha = 0.14;
    hi = "ffffff"; # top specular sheen
    hiAlpha = 0.30;
    accent = "c4a8c4"; # lavender
    accentInk = "16121a"; # text/icon on accent fills
    error = "e0533f";
  };
  light = {
    bg = "f8f9fb";
    bgAlpha = 0.55;
    surface = "e9ecf2";
    ink = "1c1f27";
    fg = "16181e";
    subtle = "5a6072";
    fillBase = "464e62";
    fillAlpha = 0.10;
    fillStrongAlpha = 0.18;
    hairlineBase = "283042";
    hairlineAlpha = 0.12;
    border = "ffffff";
    borderAlpha = 0.65;
    hi = "ffffff";
    hiAlpha = 0.95;
    accent = "c4a8c4";
    accentInk = "ffffff";
    error = "e0533f";
  };
}
