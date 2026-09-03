{
  pkgs ? import <nixpkgs> { },
}:

(pkgs.buildFHSEnv {
  name = "sourcepawn";

  targetPkgs =
    pkgs:
    (with pkgs; [
      pkgsi686Linux.stdenv.cc.cc.lib
      pkgsi686Linux.glibc
    ]);

  profile = ''
    export LD_LIBRARY_PATH="${pkgs.pkgsi686Linux.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
  '';

  runScript = "zsh";
}).env
