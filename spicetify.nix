{ stdenv, pkgs }:

stdenv.mkDerivation rec {
  name = "spicetify-2.7.1";

  src = pkgs.fetchurl {
    name = "spicetify-2.7.1-linux-amd64.tar.gz";
    url = https://github.com/khanhas/spicetify-cli/releases/download/v2.7.1/spicetify-2.7.1-linux-amd64.tar.gz;
    sha256 = "sha256-3NTMOZ7YNAE8uNVcvofqNI0CquoZx/p+xk915IzgeUE=";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out
    cp -r * $out
  '';
}
