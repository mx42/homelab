{
  description = "Infrastructure LXC + Terraform + NixOS via Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    generators.url = "github:nix-community/nixos-generators";
    terranix.url = "github:terranix/terranix";
    devenv.url = "github:cachix/devenv";
    authentik-nix.url = "github:nix-community/authentik-nix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      generators,
      terranix,
      devenv,
      authentik-nix,
      agenix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      finalModule = (
        lib.evalModules {
          modules = [
            {
              _module.args.nixpkgs = nixpkgs;
              _module.args.system = system;
            }
            ./modules/containers.nix
            ./config/_globals.nix
            ./config/_ids.nix
          ]
          ++ (import ./containers { inherit pkgs; });
        }
      );
      nixosModules = finalModule.config.nixosModule;
      terraformConfig = finalModule.config.tf;
      # lxc-def = import ./modules/lxc-template.nix;
      terraformBase = import ./modules/terraform-base.nix;

      inherit (import ./config/_globals.nix { }) globals;
    in
    {
      packages.${system} = {
        lxc-template = generators.nixosGenerate {
          inherit system;
          format = "proxmox-lxc";
          modules = [
            ./modules/lxc-template.nix
          ];
        };

        kiosk-iso = generators.nixosGenerate {
          inherit system;
          format = "iso";
          modules = [
            ./modules/nixos-kiosk-iso.nix
          ];
        };

        terraform-json = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            terraformBase
            terraformConfig
          ];
        };
      };

      nixosConfigurations = lib.mapAttrs (
        name: module:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            agenix.nixosModules.default
            authentik-nix.nixosModules.default
            module
          ];
        }
      ) nixosModules;

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

              scripts.build-kiosk-iso.exec = ''
                nix build .#kiosk-iso -o kiosk.iso
              '';

              scripts.build-terraform-json.exec = ''
                nix build .#terraform-json -o config.tf.json
                echo 'Terraform build available as config.tf.json'
              '';

              scripts.add-lxc.exec = ''
                if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                  echo "Error: invalid container ID '$2', should be a number" && exit
                fi
                if ! [ -f config/_ids.nix ]; then
                  echo "{ ... }: { id = {" > config/_ids.nix
                  echo "};\n}" >> config/_ids.nix
                fi
                if ! [[ -z "`grep "[^0-9]$2[^0-9]" config/_ids.nix`" ]]; then
                  echo "Error: container ID '$2' already used" && exit
                fi
                if [ -f containers/$1.nix ]; then
                  echo "Error: container definition '$1' already exists" && exit
                fi
                sed -i "s#};#  $1 = $2;\n  };#" config/_ids.nix
                cp containers/_cont.tmpl containers/$1.nix
                sed -i "s/#name#/$1/g" containers/$1.nix
                git add containers/$1.nix
                echo "Entry added to config/_ids.nix"
                echo "Container template copied to containers/$1.nix, please edit it"
              '';

              scripts.deploy-lxc.exec = ''
                if [ -f containers/$1.nix ]; then
                  CONTID=`grep -E "$1 ?=" config/_ids.nix | cut -d '=' -f 2 | grep -o '\<[0-9]*\>' `
                  IP_SUFFIX=$((CONTID - 1000))
                  # TODO Verify mapping exists...
                  echo "Redeploying LXC on container '$1' ('$CONTID')"
                  nixos-rebuild switch --flake .#$1 --target-host root@${globals.ip_prefix}$IP_SUFFIX
                  echo "Done."
                else
                  echo "Error: Container definition 'containers/$1.nix' not found!"
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
