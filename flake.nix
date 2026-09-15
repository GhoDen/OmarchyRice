{
  description = "My OS-agnostic system backup";

  inputs = {
    # 1. Your global unstable channel
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 2. Force Superfile to use YOUR unstable nixpkgs
    superfile = {
      url = "github:yorukot/superfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    markshot = {
      url = "github:jswysnemc/mark-shot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # (Example) Any future repositories can follow this exact same pattern:
    # some-other-app = {
    #   url = "github:owner/repo";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
# ANYONE CLONING THIS REPO: Change this string to your username!
      user = "your_username_here";
    in {
      homeConfigurations."${user}" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = { inherit inputs user; };
      modules = [ ./home.nix ];
    };
  };
}
