{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    spicetify-themes = {
      url = "github:morpheusthewhite/spicetify-themes";
      flake = false;
    };
  };

  outputs = {nixpkgs, spicetify-themes, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in rec {
    homeManagerModule = (import ./module.nix {
      themes = spicetify-themes;
      #themes = null;
    });

    packages.${system} = {
      spotify-modded = (pkgs.callPackage ./package.nix {
        inherit pkgs;
        theme = "BurntSienna";

        #theme = "Dribbblish";
        #colorScheme = "Dark";

        #theme = "Fluent";
        #colorScheme = "Nord-Dark";

        #enabledCustomApps = ["reddit"];
        #enabledExtensions = ["newRelease.js"];
        themesInput = spicetify-themes;
      });
    };

    defaultPackage.${system} = packages.${system}.spotify-modded;
  };
}
