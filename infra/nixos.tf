module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere/terraform/all-in-one"
  nixos_system_attr      = "..#nixosConfigurations.serengeti.config.system.build.toplevel"
  nixos_partitioner_attr = "..#nixosConfigurations.serengeti.config.system.build.diskoScript"
  target_host            = oci_core_instance.nix-builder.public_ip
  instance_id            = oci_core_instance.nix-builder.public_ip
  install_user           = "ubuntu"
  extra_files_script     = "${path.module}/decrypt-ssh-secret.sh"
}
