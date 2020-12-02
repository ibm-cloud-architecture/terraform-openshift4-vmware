terraform {
  required_providers {
    template = {
      source = "hashicorp/template"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
    ignition = {
      source = "community-terraform-providers/ignition"
    }
  }
  required_version = ">= 0.13"
}
