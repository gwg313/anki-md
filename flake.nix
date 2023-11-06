{
  description = "A flake for anki from markdown";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
    ...
  }: let
    withSystem = f:
      nixpkgs.lib.fold nixpkgs.lib.recursiveUpdate {} (
        map f [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-linux"
          "aarch64-darwin"
        ]
      );
  in
    withSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.${system} = {
          default = pkgs.writeShellApplication {
            name = "mdtoanki";
            runtimeInputs = with pkgs; [markdown-anki-decks];
            text = ''
              mdankideck decks output
            '';
          };
        };
        devShells.${system} = {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = with pkgs; [
              markdown-anki-decks
              alejandra
              mdl
            ];
          };
        };
        checks.${system} = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
              markdownlint.enable = true;
            };
          };
        };
      }
    );
}
