{
  description = "Infrastructure LXC + Terraform + NixOS via Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    generators.url = "github:nix-community/nixos-generators";
    terranix.url = "github:terranix/terranix";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      generators,
      terranix,
      devenv,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      containersMapping = import ./lib/ips.nix;

      containers = import ./lxc { inherit pkgs containersMapping; };

      lxc-def = import ./lib/lxc-template.nix;

      infra = import ./lib/constants.nix;

      nixosConfigurations = lib.mapAttrs (
        _: def:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ def.nixosModule ];
        }
      ) containers;

      terraformCfg = import ./lib/infra.nix;

      terraformResources = {
        resource.proxmox_lxc = lib.mapAttrs (_: def: def.terraformResource) containers;
      };

    in
    {
      packages.${system} = {
        lxc-template = generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [ lxc-def ];
          format = "proxmox-lxc";
        };

        terraform-json = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            terraformResources
            terraformCfg
          ];
        };
      };

      nixosConfigurations = nixosConfigurations;

      devShells.${system}.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          (
            { pkgs, config, ... }:
            {
              languages.opentofu.enable = true;

              scripts.build-template.exec = ''
                nix build .#lxc-template -o nixos-template
                echo 'Template should be available at nixos-template/tarball/*.tar.xz'
              '';

              scripts.build-terraform-json.exec = ''
                nix build .#terraform-json -o config.tf.json
                echo 'Terraform build available as config.tf.json'
              '';

              scripts.add-lxc.exec = ''
                if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                  echo "Error: invalid container ID '$2', should be a number" && exit
                fi
                if ! [ -f lib/ips.nix ]; then
                  echo "{" > lib/ips.nix
                  echo "}" >> lib/ips.nix
                fi
                if ! [[ -z "`grep "[^0-9]$2[^0-9]" lib/ips.nix`" ]]; then
                  echo "Error: container ID '$2' already used" && exit
                fi
                if [ -f lxc/$1.nix ]; then
                  echo "Error: container definition '$1' already exists" && exit
                fi
                sed -i "s#}#  $1 = $2;#" lib/ips.nix
                echo "}" >> lib/ips.nix
                cp lib/container.nix.template lxc/$1.nix
                git add lxc/$1.nix
                echo "Entry added to infra/ips.nix"
                echo "Container template copied to lxc/$1.nix, please edit it"
              '';

              scripts.deploy-lxc.exec = ''
                if [ -f lxc/$1.nix ]; then
                  CONTID=`grep -E "$1 ?=" lib/ips.nix | cut -d '=' -f 2 | grep -o '\<[0-9]*\>' `
                  # TODO Verify mapping exists...
                  echo "Redeploying LXC on container '$1' ('$CONTID')"
                  nixos-rebuild switch --flake .#$1 --target-host root@${infra.ip_prefix}$CONTID
                  echo "Done."
                else
                  echo "Error: Container definition 'lxc/$1.nix' not found!"
                fi
              '';

              enterShell = ''
                echo "Helper commands available:"
                echo ""
                echo "'build-template' to build the Proxmox LXC NixOS template"
                echo "'build-terraform-json' to build the Terraform config.tf.json file to apply"
                echo "'add-lxc' to prepare the template for a LXC container"
                echo "'deploy-lxc' to deploy a container configuration using nixos-rebuild"
              '';
            }
          )
        ];
      };
    };
}
