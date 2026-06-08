{
  lib,
  stdenvNoCC,
  quickshell,
  makeWrapper,
}:
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

    runHook postInstall
  '';

  meta = {
    description = "A neutral liquid-glass Quickshell desktop shell";
    homepage = "https://github.com/peteyycz/hare";
    license = lib.licenses.mit;
    mainProgram = "hare";
    platforms = lib.platforms.linux;
  };
}
