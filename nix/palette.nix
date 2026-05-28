# Neutral "liquid glass" palette: translucent grayscale surfaces meant to sit
# over any wallpaper with compositor blur behind them. Colours are hex without
# the leading '#'; *Alpha values are 0..1 opacity for the translucent surfaces.
{
  dark = {
    bg = "18181b"; # panel fill (zinc-900)
    surface = "27272a"; # nested chips/pills (zinc-800)
    fg = "f4f4f5"; # primary text/icons (zinc-100)
    subtle = "a1a1aa"; # secondary text/inactive (zinc-400)
    accent = "e4e4e7"; # active highlight (zinc-200)
    error = "f87171"; # red-400
    border = "ffffff"; # glass edge highlight
    bgAlpha = 0.55; # panel translucency
    borderAlpha = 0.10; # glass edge opacity
  };
  light = {
    bg = "fafafa"; # zinc-50
    surface = "f4f4f5"; # zinc-100
    fg = "18181b"; # zinc-900
    subtle = "52525b"; # zinc-600
    accent = "3f3f46"; # zinc-700
    error = "dc2626"; # red-600
    border = "ffffff";
    bgAlpha = 0.6;
    borderAlpha = 0.55;
  };
}
