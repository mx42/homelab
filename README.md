# NixOS x Proxmox infra configuration with Terranix

This repository allows to manage LXC containers on Proxmox.

It's supposed to be used from an host where `nixos-rebuild` is available.

  - Uses `nix-community/generators` to build a LXC template with a base NixOS container
  - Uses `terranix` to build the infra definition and `opentofu` to deploy it on Proxmox
  - Uses `nixos-rebuild` to deploy the configuration on the container

My main objective was to have a "light" definition for the containers and to be able to use Nix to factorize configuration.

# Usage

## Prepare the infra constants
- `cp infra/constants.nix.template infra/constants.nix`
- adapt `infra/constants.nix` to match your needs
- touch `infra/ips.nix`
- remove both these files from `.gitignore` and `git add` them. 

## Build NixOS template
- modify `infra/lxc-template.nix` as needed
- run `build-template`
- template available in `nixos-template/tarball/`
(.tar.xz to be uploaded to Proxmox)

TODO Script the Proxmox Template upload if possible.

## Prepare Terraform
- create a user/role etc on Proxmox (see [the provider documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs))
- `cp terraform.tfvars.example terraform.tfvars`
- edit `terraform.tfvars` to fill in values
- adapt the terraform base config as needed in `infra/main.nix`
- run `tofu init`

## Adapt NixOS / Terraform modules building
- edit `lib/containers.nix` to change how a container definition is translated to TF / NixOS config (in particular check the template name)

## Create containers definitions
- `cp containers/lxc-cont.nix.template containers/lxc-#NAME#.nix` 
- edit `containers/lxc-#NAME#.nix` as needed
- run `build-terraform-json`
- run `tofu plan` and review the plan
- run `tofu apply`, hopefully without errors
- run `deploy #NAME#`

## Update container
- edit `containers/lxc-#NAME#.nix` as needed
- if the container specs have changed, do all as above
- otherwise you can just run `deploy #NAME#`


