{ pkgs, lib, inputs, user, ... }:
let
  rawLines = lib.splitString "\n" (builtins.readFile ./packages.txt);

  collected = lib.foldl' (acc: line:
    let sectionMatch = builtins.match "\\[([a-zA-Z-]+)\\]" line;
    in
    if sectionMatch != null then
      acc // { current = builtins.elemAt sectionMatch 0; }
    else if line == "" || lib.strings.hasPrefix "#" line then
      acc
    else
      acc // { "${acc.current}" = (acc."${acc.current}" or []) ++ [ line ]; }
  ) { current = null; nix = []; "nix-flake" = []; } rawLines;

  resolvePkg = name:
    if builtins.hasAttr name pkgs
    then [ (builtins.getAttr name pkgs) ]
    else builtins.trace "packages.txt [nix]: '${name}' not found in nixpkgs — skipping" [];

  resolveFlakePkg = name:
    if builtins.hasAttr name inputs
    then [ inputs.${name}.packages.${pkgs.system}.default ]
    else builtins.trace "packages.txt [nix-flake]: '${name}' has no matching flake input in flake.nix — skipping" [];

  nixPackages = lib.concatMap resolvePkg collected.nix;
  flakePackages = lib.concatMap resolveFlakePkg collected."nix-flake";
in
{
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.11";
  targets.genericLinux.enable = true;

  home.packages = nixPackages ++ flakePackages;

  programs.home-manager.enable = true;
}
