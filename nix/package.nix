{
  lib,
  stdenvNoCC,
  quickshell,
  makeWrapper,
  imagemagick,
  writeShellApplication,
}:
let
  # Picks "dark" or "light" from a wallpaper's mean luminance and writes it to
  # $XDG_STATE_HOME/hare/tone. Bright wallpaper -> dark glass (contrast), dark
  # wallpaper -> light glass. The shell watches that file and re-themes live.
  hare-tone = writeShellApplication {
    name = "hare-tone";
    runtimeInputs = [ imagemagick ];
    text = ''
      wp="''${1:-''${HARE_WALLPAPER:-}}"
      out="''${XDG_STATE_HOME:-$HOME/.local/state}/hare/tone"
      mkdir -p "$(dirname "$out")"

      if [ -z "$wp" ] || [ ! -f "$wp" ]; then
        echo dark > "$out"
        exit 0
      fi

      lum=$(magick "$wp" -colorspace Gray -resize 1x1 -depth 8 -format '%[fx:mean]' info: 2>/dev/null || echo 1)
      if awk -v l="$lum" 'BEGIN { exit !(l > 0.5) }'; then
        echo dark > "$out"
      else
        echo light > "$out"
      fi
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "hare";
  version = "0.1.0";

  src = ../shell;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hare
    cp -r ./* $out/share/hare/

    mkdir -p $out/bin
    makeWrapper ${lib.getExe quickshell} $out/bin/hare \
      --add-flags "--path $out/share/hare"
    ln -s ${lib.getExe hare-tone} $out/bin/hare-tone

    runHook postInstall
  '';

  passthru = { inherit hare-tone; };

  meta = {
    description = "A neutral liquid-glass Quickshell desktop shell";
    homepage = "https://github.com/peteyycz/hare";
    license = lib.licenses.mit;
    mainProgram = "hare";
    platforms = lib.platforms.linux;
  };
}
