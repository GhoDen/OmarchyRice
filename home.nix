
{ pkgs, inputs, user, ... }: {
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  # 1. INSTALL APPLICATIONS
  home.packages = [
    pkgs.git
    
    # SysInfo Fetcher
    pkgs.fastfetch
    pkgs.imagemagick
    # Shell
    pkgs.fish
    # Window Manager
    pkgs.hyprland
    # Polkit
    pkgs.hyprpolkitagent
    # XDG Portal
    pkgs.xdg-desktop-portal-hyprland
    # Wallpaper
    pkgs.hyprpaper
    # Font
    pkgs.nerd-fonts.jetbrains-mono
    # Terminal
    pkgs.kitty
    # Editor
    pkgs.neovim
    pkgs.lua-language-server
    pkgs.tree-sitter-cli
    # Custom UI
    pkgs.quickshell
    pkgs.networkmanager
    pkgs.brightnessctl
    # Browser
    pkgs.qutebrowser
    # Shell Prompt
    pkgs.starship
    # File Manager
    inputs.superfile.packages.${pkgs.system}.default
    # Clipboard
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.cliphist
    # Other
    pkgs.openssh
    pkgs.less
    pkgs.fzf
    pkgs.btop
    pkgs.man-db
    pkgs.tldr
    pkgs.bat
    # Remaps
    pkgs.keyd
    # Bluetooth
    pkgs.bluez
    pkgs.bluez-libs
    pkgs.bluez-utils
    # 1password dep
    pkgs.jq
    # Screenshots and recordings
    pkgs.obs-studio
    inputs.markshot.packages.${pkgs.system}.default
    # Greeters
    pkgs.greetd
    # PDF Viewer
    pkgs.zathura
    pkgs.zathura-pdf-mupdf
    pkgs.tesseract
    # C/C++
    pkgs.clang
    pkgs.cmake
    pkgs.bear
    pkgs.lldb
  ];

  # 2. MANAGE DOTFILES NATIVELY
  home.file = {
    ".bashrc".text = ''
      alias update-sys="home-manager switch --flake ~/.dotfiles#yourusername"
      echo "Welcome to your reproducible environment!"
    '';
    ".config/fastfetch/config.jsonc".source = ./.config/fastfetch/config.jsonc;
    ".config/fish".source = ./.config/fish;
    ".config/hypr/hyprland.lua".source = ./.config/hypr/hyprland.lua;
    ".config/hypr/hyprpaper.conf".source = ./.config/hypr/hyprpaper.conf;
    ".config/kitty/kitty.conf".source = ./.config/kitty/kitty.conf;
    ".config/nvim".source = ./.config/nvim;
    ".config/quickshell".source = ./.config/quickshell;
    ".config/qutebrowser/userscripts".source = ./.config/qutebrowser/userscripts;
    ".config/starship.toml".source = ./.config/starship.toml;
  };

  programs.home-manager.enable = true;

  # TODO: Not changed in this config
  # - mark-shot (screenshot tool - may need custom packaging or AUR reference)
  # - valent (phone connect - may need custom packaging or AUR reference)
  # - qview (image viewer - may need custom packaging or AUR reference)
  # - snappy-switcher (window switcher - may need custom packaging or AUR reference)
  # - 1password and 1password-cli (may need unfree packages enabled in flake.nix)
  # - keyd daemon activation and system-level configuration
  # - greetd daemon setup and service activation
  # - bluetooth daemon setup and service activation
  # - Fish shell set as default shell
  # - TreeSitter QML plugin installation
  # - Custom Ricing wallpapers and icons
  
  # TODO: Consider adding to flake.nix
  # - allowUnfree = true for 1password packages
  # - overlays for AUR packages (mark-shot, valent, qview, snappy-switcher)
  # - systemd user services for keyd, greetd, and bluetooth
  # - sessionVariables for XDG paths if needed
  # - shellAliases for fish configuration
}
