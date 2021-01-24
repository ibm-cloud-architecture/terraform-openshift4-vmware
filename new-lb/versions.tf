terraform {
  required_providers {
    ignition = {
      source = "community-terraform-providers/ignition"
    }
    vcd = {
      source = "vmware/vcd"
    }
  }
  required_version = ">= 0.13"
}
