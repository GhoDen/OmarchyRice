{
  description = "My OS-agnostic system backup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superfile = {
      url = "github:yorukot/superfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    markshot = {
      url = "github:jswysnemc/mark-shot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    edgepad = {
      url = "github:assembledev/edgepad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    limusic = {
      url = "github:GhoDen/limusic";
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
      system = "x86_64-linux";
      user   = "denver";
    in {
      homeConfigurations."${user}" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { inherit system; };
      extraSpecialArgs = { inherit inputs user; };
      modules = [ ./home.nix ];
    };
  };
}
