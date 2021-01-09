# force local ignition provider binary
# provider "ignition" {
#   version = "0.0.0"
# }

locals {
  app_name           = "${var.cluster_id}-${var.base_domain}"
  vcd_net_name        = var.vm_network
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

  vapp_name         = local.app_name
#  is_fenced = true

 # Comment below line to create an isolated vApp network
  org_network_name  = var.vm_network
  depends_on = [vcd_vapp.app_name]
}


resource "vcd_vapp" "app_name" {
  org          = var.vcd_org
  vdc          = var.vcd_vdc

  name = local.app_name

}

resource "tls_private_key" "installkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
  
  depends_on = [vcd_vapp_org_network.vappOrgNet]
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
module "lb" {
  count = var.create_loadbalancer_vm ? 1 : 0
  source        = "./lb"
  lb_ip_address = var.lb_ip_address

  api_backend_addresses = flatten([
    var.bootstrap_ip_address,
    var.control_plane_ip_addresses
  ])

  ingress_backend_addresses = var.compute_ip_addresses
  ssh_public_key            = chomp(tls_private_key.installkey.public_key_openssh)

  cluster_domain = local.cluster_domain

  bootstrap_ip      = var.bootstrap_ip_address
  control_plane_ips = var.control_plane_ip_addresses
  vm_dns_addresses  = var.vm_dns_addresses
  dns_addresses = var.create_loadbalancer_vm ? [var.lb_ip_address] : var.vm_dns_addresses

  dns_ip_addresses = zipmap(
    concat(
      local.bootstrap_fqdns,
      local.api_lb_fqdns,
      local.control_plane_fqdns,
      local.compute_fqdns,
      local.storage_fqdns
    ),
    concat(
      list(var.bootstrap_ip_address),
      [for idx in range(length(local.api_lb_fqdns)) : var.lb_ip_address],
      var.control_plane_ip_addresses,
      var.compute_ip_addresses,
      var.storage_ip_addresses
    ),
  )

  loadbalancer_ip   = var.loadbalancer_lb_ip_address
  loadbalancer_cidr = var.loadbalancer_lb_machine_cidr

  hostnames_ip_addresses  = zipmap(local.lb_fqdns, [var.lb_ip_address])
  machine_cidr            = var.machine_cidr
  network_id              = var.vm_network
#  loadbalancer_network_id = var.loadbalancer_network == "" ? "" : data.vsphere_network.loadbalancer_network[0].id
  loadbalancer_network_id = var.loadbalancer_network 

   vcd_catalog             = var.vcd_catalog
   lb_template             = var.lb_template
  
   num_cpus                = 2
   vcd_vdc                 = var.vcd_vdc
   vcd_org                 = var.vcd_org 
   app_name                = local.app_name
}
module "ignition" {
  source              = "./ignition"
  ssh_public_key      = chomp(tls_private_key.installkey.public_key_openssh)
  base_domain         = var.base_domain
  cluster_id          = var.cluster_id
  cluster_cidr        = var.openshift_cluster_cidr
  cluster_hostprefix  = var.openshift_host_prefix
  cluster_servicecidr = var.openshift_service_cidr
  machine_cidr        = var.machine_cidr
  pull_secret         = var.openshift_pull_secret
  openshift_version   = var.openshift_version
  total_node_count    = var.compute_count + var.storage_count
}

module "bootstrap" {
  source = "./vm"

  ignition = module.ignition.append_bootstrap

  hostnames_ip_addresses = zipmap(
    local.bootstrap_fqdns,
    [var.bootstrap_ip_address]
  )


  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr
#  vm_template             = var.rhcos_template
  network_id              = var.vm_network
  vcd_catalog             = var.vcd_catalog
  vcd_vdc                 = var.vcd_vdc
  vcd_org                 = var.vcd_org 
  app_name                = local.app_name
  rhcos_template          = var.rhcos_template
  num_cpus      = 2
  memory        = 8192
  dns_addresses = var.create_loadbalancer_vm ? [var.lb_ip_address] : var.vm_dns_addresses
}

module "control_plane_vm" {
  source = "./vm"

  hostnames_ip_addresses = zipmap(
    local.control_plane_fqdns,
    var.control_plane_ip_addresses
  )

  ignition = module.ignition.master_ignition

  network_id            = var.vm_network
  vcd_catalog             = var.vcd_catalog
  vcd_vdc                 = var.vcd_vdc
  vcd_org                 = var.vcd_org 
  app_name                = local.app_name
  rhcos_template          = var.rhcos_template


  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr

  num_cpus      = var.control_plane_num_cpus
  memory        = var.control_plane_memory
  dns_addresses = var.create_loadbalancer_vm ? [var.lb_ip_address] : var.vm_dns_addresses
}

module "compute_vm" {
  source = "./vm"

  hostnames_ip_addresses = zipmap(
    local.compute_fqdns,
    var.compute_ip_addresses
  )

  ignition = module.ignition.worker_ignition

 
  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr
  network_id            = var.vm_network
  vcd_catalog             = var.vcd_catalog
  vcd_vdc                 = var.vcd_vdc
  vcd_org                 = var.vcd_org 
  app_name                = local.app_name
  rhcos_template          = var.rhcos_template

  num_cpus      = var.compute_num_cpus
  memory        = var.compute_memory
  dns_addresses = var.create_loadbalancer_vm ? [var.lb_ip_address] : var.vm_dns_addresses
}

module "storage_vm" {
  source = "./vm"

  hostnames_ip_addresses = zipmap(
    local.storage_fqdns,
    var.storage_ip_addresses
  )

  ignition = module.ignition.worker_ignition

  network_id            = var.vm_network
  vcd_catalog             = var.vcd_catalog
  vcd_vdc                 = var.vcd_vdc
  vcd_org                 = var.vcd_org 
  app_name                = local.app_name
  rhcos_template          = var.rhcos_template

  cluster_domain = local.cluster_domain
  machine_cidr   = var.machine_cidr

  num_cpus      = var.storage_num_cpus
  memory        = var.storage_memory
  dns_addresses = var.create_loadbalancer_vm ? [var.lb_ip_address] : var.vm_dns_addresses
}
