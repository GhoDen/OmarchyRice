{ pkgs, inputs, user, ... }: {
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  # 1. INSTALL APPLICATIONS
  home.packages = [
    pkgs.git
    
    pkgs.kitty
    pkgs.mesa-demos

    pkgs.fastfetch
    # Install from git URL due to out of date nix package.
    inputs.superfile.packages.${pkgs.system}.default
  ];

  # 2. MANAGE DOTFILES NATIVELY
  home.file.".bashrc".text = ''
    alias update-sys="home-manager switch --flake ~/.dotfiles#yourusername"
    echo "Welcome to your reproducible environment!"
  '';

  programs.home-manager.enable = true;
}
