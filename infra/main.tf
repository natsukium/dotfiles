terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
    sops = {
      source = "carlpett/sops"
    }
  }
}

data "sops_file" "oci-secret" {
  source_file = "oci_secrets.yaml"
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  private_key  = data.sops_file.oci-secret.data["private_key"]
  fingerprint  = var.fingerprint
  region       = var.region
}

resource "oci_identity_compartment" "tf-compartment" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = "nix-builder"
}

resource "oci_core_vcn" "nix-builder" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = oci_identity_compartment.tf-compartment.id
  display_name   = "nix-builder"
}

resource "oci_core_subnet" "nix-builder" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.nix-builder.id
  route_table_id = oci_core_route_table.nix-builder.id
}

resource "oci_core_internet_gateway" "nix-builder" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.nix-builder.id
  enabled        = "true"
}

resource "oci_core_route_table" "nix-builder" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.nix-builder.id
    destination       = "0.0.0.0/0"
  }
  vcn_id = oci_core_vcn.nix-builder.id
}

resource "oci_core_security_list" "nix-builder" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.nix-builder.id
}

resource "oci_core_instance" "nix-builder" {
  availability_domain = "kaTU:AP-OSAKA-1-AD-1"
  compartment_id      = oci_identity_compartment.tf-compartment.id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = "24"
    ocpus         = "4"
  }
  display_name = "serengeti"

  create_vnic_details {
    assign_ipv6ip             = "false"
    assign_private_dns_record = "true"
    assign_public_ip          = "true"
    subnet_id                 = oci_core_subnet.nix-builder.id
  }

  source_details {
    boot_volume_size_in_gbs = "200"
    boot_volume_vpus_per_gb = "10"
    source_id               = "ocid1.image.oc1.ap-osaka-1.aaaaaaaa4md3pz5poqsce3g4vqjxw4cp4imv55s7ooszje4tpwl54imsl4hq"
    source_type             = "image"
  }

  metadata = {
    "ssh_authorized_keys" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu tomoya.otabi@gmail.com"
  }
}

output "ip-address" {
  value = oci_core_instance.nix-builder.public_ip
}
