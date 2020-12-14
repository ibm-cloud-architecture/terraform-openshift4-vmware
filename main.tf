# force local ignition provider binary
# provider "ignition" {
#   version = "0.0.0"
# }

locals {
  app_name           = "${var.cluster_id}-${var.base_domain}"
  cluster_domain      = "${var.cluster_id}.${var.base_domain}"
  bootstrap_fqdns     = ["bootstrap-0.${local.cluster_domain}"]
  lb_fqdns            = ["lb-0.${local.cluster_domain}"]
  api_lb_fqdns        = formatlist("%s.%s", ["api", "api-int", "*.apps"], local.cluster_domain)
  control_plane_fqdns = [for idx in range(var.control_plane_count) : "control-plane-${idx}.${local.cluster_domain}"]
  compute_fqdns       = [for idx in range(var.compute_count) : "compute-${idx}.${local.cluster_domain}"]
  storage_fqdns       = [for idx in range(var.storage_count) : "storage-${idx}.${local.cluster_domain}"]
}

provider "vcd" {
  user                 = var.vcd_user
  password             = var.vcd_password
  org                  = var.vcd_org
  url                  = var.vcd_url
  max_retry_timeout    = 30
  allow_unverified_ssl = true
  logging              = true
}

resource "vcd_vapp_org_network" "vappOrgNet" {
  org          = var.vcd_org
  vdc          = var.vcd_vdc

  vapp_name         = app_name

 # Comment below line to create an isolated vApp network
  org_network_name  = var.vm_network
  depends_on = [vcd_vapp.app_name]
}


resource "vcd_vapp" "app_name" {
  org          = var.vcd_org
  vdc          = var.vcd_vdc

  name = app_name

}
#

#provider "vsphere" {
#  user                 = var.vsphere_user
#  password             = var.vsphere_password
#  vsphere_server       = var.vsphere_server
#  allow_unverified_ssl = true
#}

#data "vsphere_datacenter" "dc" {
#  name = var.vsphere_datacenter
#}

#data "vsphere_compute_cluster" "compute_cluster" {
#  name          = var.vsphere_cluster
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

#data "vsphere_datastore" "datastore" {
#  name          = var.vsphere_datastore
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

#data "vsphere_network" "network" {
#  name          = var.vm_network
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

#data "vsphere_network" "loadbalancer_network" {
#  count         = var.loadbalancer_network == "" ? 0 : 1
#  name          = var.loadbalancer_network
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

#data "vsphere_virtual_machine" "template" {
#  name          = var.vm_template
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

#resource "vsphere_resource_pool" "resource_pool" {
#  name                    = var.cluster_id
#  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
#}

#resource "vsphere_folder" "folder" {
#  path          = var.cluster_id
#  type          = "vm"
#  datacenter_id = data.vsphere_datacenter.dc.id
#}

resource "tls_private_key" "installkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "write_private_key" {
  content         = tls_private_key.installkey.private_key_pem
  filename        = "${path.root}/artifacts/openshift_rsa"
  file_permission = 0600
}

resource "local_file" "write_public_key" {
  content         = tls_private_key.installkey.public_key_openssh
  filename        = "${path.root}/artifacts/openshift_rsa.pub"
  file_permission = 0600
}
