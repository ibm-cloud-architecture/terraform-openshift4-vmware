# force local ignition provider binary
# provider "ignition" {
#   version = "0.0.0"
# }

locals {
  cluster_domain      = "${var.cluster_id}.${var.base_domain}"
  bootstrap_fqdns     = ["bootstrap-0.${local.cluster_domain}"]
  control_plane_fqdns = [for idx in range(var.control_plane_count) : "control-plane-${idx}.${local.cluster_domain}"]
  compute_fqdns       = [for idx in range(var.compute_count) : "compute-${idx}.${local.cluster_domain}"]
  storage_fqdns       = [for idx in range(var.storage_count) : "storage-${idx}.${local.cluster_domain}"]
  # ssh_public_key      = var.ssh_public_key == "" ? chomp(tls_private_key.installkey[0].public_key_openssh) : chomp(file(pathexpand(var.ssh_public_key)))
  ssh_public_key      = var.ssh_public_key
  folder_path         = var.vsphere_folder == "" ? var.cluster_id : var.vsphere_folder
  resource_pool_id    = var.vsphere_preexisting_resourcepool ? data.vsphere_resource_pool.resource_pool[0].id : vsphere_resource_pool.resource_pool[0].id
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vm_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_resource_pool" "resource_pool" {
  count = var.vsphere_preexisting_resourcepool ? 0 : 1

  name                    = var.vsphere_resource_pool == "" ? var.cluster_id : var.vsphere_resource_pool
  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
}

data "vsphere_resource_pool" "resource_pool" {
  count = var.vsphere_preexisting_resourcepool ? 1 : 0

  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folder" {
  count = var.vsphere_preexisting_folder ? 0 : 1

  path          = var.vsphere_folder == "" ? var.cluster_id : var.vsphere_folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "tls_private_key" "installkey" {
  count = var.ssh_public_key == "" ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "write_private_key" {
  count = var.ssh_public_key == "" ? 1 : 0

  content         = tls_private_key.installkey[0].private_key_pem
  filename        = "${path.root}/installer/${var.cluster_id}/sshkeys/openshift_rsa"
  file_permission = 0600
}

resource "local_file" "write_public_key" {
  count = var.ssh_public_key == "" ? 1 : 0

  content         = tls_private_key.installkey[0].public_key_openssh
  filename        = "${path.root}/installer/${var.cluster_id}/sshkeys/openshift_rsa.pub"
  file_permission = 0600
}

module "ignition" {
  source              = "./ignition"
  ssh_public_key      = local.ssh_public_key
  base_domain         = var.base_domain
  cluster_id          = var.cluster_id
  cluster_cidr        = var.openshift_cluster_cidr
  cluster_hostprefix  = var.openshift_host_prefix
  cluster_servicecidr = var.openshift_service_cidr
  machine_cidr        = var.machine_cidr
  vsphere_server      = var.vsphere_server
  vsphere_username    = var.vsphere_user
  vsphere_password    = var.vsphere_password
  vsphere_datacenter  = var.vsphere_datacenter
  vsphere_datastore   = var.vsphere_datastore
  vsphere_cluster     = var.vsphere_cluster
  vsphere_network     = var.vm_network
  vsphere_folder      = local.folder_path
  api_vip             = var.create_openshift_vips ? var.openshift_api_virtualip : ""
  ingress_vip         = var.create_openshift_vips ? var.openshift_ingress_virtualip : ""
  pull_secret         = var.openshift_pull_secret
  openshift_version   = var.openshift_version
  total_node_count    = var.compute_count + var.storage_count
  worker_mtu          = var.openshift_worker_mtu
  ntp_server          = var.openshift_ntp_server
  airgapped           = var.airgapped
  proxy_config        = var.proxy_config
  trust_bundle        = var.openshift_additional_trust_bundle
}

module "bootstrap" {
  source = "./vm"

  ignition = module.ignition.bootstrap_ignition

  hostnames_ip_addresses = zipmap(
    local.bootstrap_fqdns,
    [var.bootstrap_ip_address]
  )

  resource_pool_id      = local.resource_pool_id
  datastore_id          = data.vsphere_datastore.datastore.id
  datacenter_id         = data.vsphere_datacenter.dc.id
  network_id            = data.vsphere_network.network.id
  folder_id             = local.folder_path
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  template_uuid         = data.vsphere_virtual_machine.template.id
  disk_thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned

  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr

  num_cpus      = 2
  memory        = 8192
  disk_size     = 60
  dns_addresses = var.vm_dns_addresses
  vm_gateway    = var.vm_gateway == null ? cidrhost(var.machine_cidr, 1) : var.vm_gateway
}

module "control_plane_vm" {
  source = "./vm"

  hostnames_ip_addresses = zipmap(
    local.control_plane_fqdns,
    var.control_plane_ip_addresses
  )

  ignition = module.ignition.master_ignition

  resource_pool_id      = local.resource_pool_id
  datastore_id          = data.vsphere_datastore.datastore.id
  datacenter_id         = data.vsphere_datacenter.dc.id
  network_id            = data.vsphere_network.network.id
  folder_id             = local.folder_path
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  template_uuid         = data.vsphere_virtual_machine.template.id
  disk_thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned

  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr

  num_cpus      = var.control_plane_num_cpus
  memory        = var.control_plane_memory
  disk_size     = var.control_plane_disk_size
  dns_addresses = var.vm_dns_addresses
  vm_gateway    = var.vm_gateway == null ? cidrhost(var.machine_cidr, 1) : var.vm_gateway
}

module "compute_vm" {
  source = "./vm"

  hostnames_ip_addresses = zipmap(
    local.compute_fqdns,
    var.compute_ip_addresses
  )

  ignition = module.ignition.worker_ignition

  resource_pool_id      = local.resource_pool_id
  datastore_id          = data.vsphere_datastore.datastore.id
  datacenter_id         = data.vsphere_datacenter.dc.id
  network_id            = data.vsphere_network.network.id
  folder_id             = local.folder_path
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  template_uuid         = data.vsphere_virtual_machine.template.id
  disk_thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned

  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr

  num_cpus      = var.compute_num_cpus
  memory        = var.compute_memory
  disk_size     = var.compute_disk_size
  dns_addresses = var.vm_dns_addresses
  vm_gateway    = var.vm_gateway == null ? cidrhost(var.machine_cidr, 1) : var.vm_gateway
}

module "storage_vm" {
  source = "./vm"

  hostnames_ip_addresses = zipmap(
    local.storage_fqdns,
    var.storage_ip_addresses
  )

  ignition = module.ignition.worker_ignition

  resource_pool_id      = local.resource_pool_id
  datastore_id          = data.vsphere_datastore.datastore.id
  datacenter_id         = data.vsphere_datacenter.dc.id
  network_id            = data.vsphere_network.network.id
  folder_id             = local.folder_path
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  template_uuid         = data.vsphere_virtual_machine.template.id
  disk_thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned

  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr

  num_cpus      = var.storage_num_cpus
  memory        = var.storage_memory
  disk_size     = var.storage_disk_size
  dns_addresses = var.vm_dns_addresses
  vm_gateway    = var.vm_gateway == null ? cidrhost(var.machine_cidr, 1) : var.vm_gateway
}

