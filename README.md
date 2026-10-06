## spencer-macro-flake

# example installation:

add the flake to your flake.nix:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    smu.url = "github:FloofyIV/spencer-macro-flake";
    smu.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, smu, ... }: {
    nixosConfigurations.nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix
        smu.nixosModules.default
      ];
    };
  };
}
```

!! you may also need to add this if the nethelper daemon fails to start or prompt root access!!
``security.polkit.enablePkexecWrapper = true;``

add the smu service to your configuration.nix:
```nix
{ ... }:

{
  services.smu.enable = true; # this gives smu the required permissions for monitoring global input
}
```

# how to update:
```
cd /etc/nixos
sudo nix flake update smu
sudo nixos-rebuild switch --flake /etc/nixos#$HOSTNAME
```
