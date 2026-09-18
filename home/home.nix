{ pkgs, lib, inputs, user, ... }:
let
  rawLines = lib.splitString "\n" (builtins.readFile ./packages.txt);

  collected = lib.foldl' (acc: line:
  let
    isHeader = lib.strings.hasPrefix "[" line && lib.strings.hasSuffix "]" line;
    sectionName =
      if isHeader
      then lib.strings.removeSuffix "]" (lib.strings.removePrefix "[" line)
      else null;
  in
  if sectionName != null then
    acc // { current = sectionName; }
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

  # Starship Config
  home.file.".config/starship.toml".source = ../dotfiles/starship/starship.toml;
  # Kitty Config
  home.file.".config/kitty/kitty.conf".source = ../dotfiles/kitty/kitty.conf;
  # Fish Config
  home.file.".config/fish/config.fish".source = ../dotfiles/fish/config.fish;
  # Fastfetch Config
  home.file.".config/fastfetch/config.jsonc".source = ../dotfiles/fastfetch/config.jsonc;
  # Qutebrowser Config
  home.file.".config/qutebrowser/config.py".source = ../dotfiles/qutebrowser/config.py;
  home.file.".config/qutebrowser/theme.py.tpl".source = ../dotfiles/qutebrowser/theme.py.tpl;
  home.file.".config/omarchy/hooks/theme-set.d/qutebrowser_theme_hook".source = ../dotfiles/qutebrowser/qutebrowser_theme_hook;
  # Biopass Config
  home.file.".config/com.ticklab.biopass/config.yaml".source = ../dotfiles/biopass/config.yaml;
  # Hyprland Config
  home.file.".config/hypr/looknfeel.lua".source = ../dotfiles/hypr/looknfeel.lua;
  home.file.".config/hypr/input.lua".source = ../dotfiles/hypr/input.lua;
  # NeoVim Config
  home.file.".config/nvim/init.lua".source = ../dotfiles/nvim/init.lua;
  home.file.".config/nvim/lua/config/custom.lua".source = ../dotfiles/nvim/lua/config/custom.lua;
  home.file.".config/nvim/lua/config/init.lua".source = ../dotfiles/nvim/lua/config/init.lua;
  home.file.".config/nvim/lua/config/lazy.lua".source = ../dotfiles/nvim/lua/config/lazy.lua;
  home.file.".config/nvim/lua/config/lsp.lua".source = ../dotfiles/nvim/lua/config/lsp.lua;
  home.file.".config/nvim/lua/config/remap.lua".source = ../dotfiles/nvim/lua/config/remap.lua;
  home.file.".config/nvim/lua/lsp/clangd.lua".source = ../dotfiles/nvim/lua/lsp/clangd.lua;
  home.file.".config/nvim/lua/lsp/lua_ls.lua".source = ../dotfiles/nvim/lua/lsp/lua_ls.lua;
  home.file.".config/nvim/lua/lsp/marksman.lua".source = ../dotfiles/nvim/lua/lsp/marksman.lua;
  home.file.".config/nvim/lua/lsp/qmlls.lua".source = ../dotfiles/nvim/lua/lsp/qmlls.lua;
  home.file.".config/nvim/lua/lsp/rust.lua".source = ../dotfiles/nvim/lua/lsp/rust.lua;
  home.file.".config/nvim/lua/plugins/99.lua".source = ../dotfiles/nvim/lua/plugins/99.lua;
  home.file.".config/nvim/lua/plugins/colorizer.lua".source = ../dotfiles/nvim/lua/plugins/colorizer.lua;
  home.file.".config/nvim/lua/plugins/lspconfig.lua".source = ../dotfiles/nvim/lua/plugins/lspconfig.lua;
  home.file.".config/nvim/lua/plugins/lualine.lua".source = ../dotfiles/nvim/lua/plugins/lualine.lua;
  home.file.".config/nvim/lua/plugins/markdown.lua".source = ../dotfiles/nvim/lua/plugins/markdown.lua;
  home.file.".config/nvim/lua/plugins/telescope.lua".source = ../dotfiles/nvim/lua/plugins/telescope.lua;
  home.file.".config/nvim/lua/plugins/tokyonight.lua".source = ../dotfiles/nvim/lua/plugins/tokyonight.lua;
  home.file.".config/nvim/lua/plugins/treesitter.lua".source = ../dotfiles/nvim/lua/plugins/treesitter.lua;
  

  programs.home-manager.enable = true;
}
