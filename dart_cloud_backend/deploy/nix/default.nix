# default.nix - Entry point for nix-build
# Usage: nix-build

{ pkgs ? import <nixpkgs> {} }:

let
  dart = pkgs.dart;
  
in pkgs.stdenv.mkDerivation {
  pname = "dart-cloud-backend";
  version = "1.0.0";

  src = ./..;

  nativeBuildInputs = [ dart ];

  buildPhase = ''
    export HOME=$TMPDIR
    
    # Get dependencies
    dart pub get --offline || dart pub get
    
    # Compile to native executable
    dart compile exe bin/server.dart -o bin/server
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/dart-cloud-backend
    
    # Install binary
    cp bin/server $out/bin/dart-cloud-backend
    
    # Install configuration files
    cp -r deploy $out/share/dart-cloud-backend/
    cp pubspec.yaml $out/share/dart-cloud-backend/
  '';

  meta = with pkgs.lib; {
    description = "Backend server for hosting and managing Dart serverless functions";
    homepage = "https://github.com/liodali/ContainerPub";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [];
  };
}
