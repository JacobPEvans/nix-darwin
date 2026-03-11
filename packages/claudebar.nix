{
  stdenvNoCC,
  fetchurl,
  undmg,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ClaudeBar";
  version = "0.3.6";

  src = fetchurl {
    url = "https://github.com/tddworks/ClaudeBar/releases/download/v${version}/ClaudeBar-${version}.dmg";
    hash = "sha256-Z9FX3w7RHpiHa2xNrQmgkc7PxvNY28YYbn/Zxw4UO2s=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -r ClaudeBar.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "macOS menu bar app for AI coding assistant quota monitoring";
    homepage = "https://github.com/tddworks/ClaudeBar";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
