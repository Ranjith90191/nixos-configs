{
  description = "yhwach's NixOS system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankcalendar = {
      url = "github:AvengeMedia/dankcalendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, niri, dms, dankcalendar, dsearch, helium-browser, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "yhwach";
    in
    {
      nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/mymachine/configuration.nix
          niri.nixosModules.niri
          dms.nixosModules.greeter
          dankcalendar.nixosModules.dank-calendar

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.${username} = {
              imports = [
                ./home/home.nix
                dms.homeModules.dank-material-shell
                dms.homeModules.niri
                dankcalendar.homeModules.dank-calendar
                dsearch.homeModules.dsearch
                helium-browser.homeModules.default
              ];
            };
          }
        ];
      };
    };
}
