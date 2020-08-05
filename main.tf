provider "vsphere" {
  user                 = var.vsphere_username
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.vsphere_allow_insecure
}

# SSH Key for VMs
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

module "helper" {
  source             = "./helper"
  datacenter_id      = data.vsphere_datacenter.datacenter.id
  datastore_id       = data.vsphere_datastore.node.id
  resource_pool_id   = var.preexisting_resource_pool ? data.vsphere_resource_pool.pool[0].id : vsphere_resource_pool.pool[0].id
  folder_id          = vsphere_folder.folder.path
  vminfo             = var.helper
  public_ip          = var.helper_public_ip
  private_ip         = var.helper_private_ip
  public_network_id  = data.vsphere_network.public.id
  private_network_id = data.vsphere_network.private.id
  public_gateway     = var.public_network_gateway
  private_gateway    = var.private_network_gateway
  public_netmask     = var.public_network_netmask
  private_netmask    = var.private_network_netmask
  cluster_id         = var.openshift_cluster_id
  base_domain        = var.openshift_base_domain
  dns_servers        = var.public_network_nameservers
  ssh_private_key    = tls_private_key.installkey.private_key_pem
  ssh_public_key     = tls_private_key.installkey.public_key_openssh
  bootstrap_hostname = var.bootstrap_hostname
  bootstrap_ip       = var.bootstrap_ip
  master_hostnames   = var.master_hostnames
  master_ips         = var.master_ips
  worker_hostnames   = var.worker_hostnames
  worker_ips         = var.worker_ips
  storage_hostnames  = var.storage_hostnames
  storage_ips        = var.storage_ips
  binaries           = var.binaries
}

module "createisos" {
  source = "./createisos"
  dependson = [
    module.helper.module_completed
  ]
  binaries              = var.binaries
  bootstrap             = var.bootstrap
  bootstrap_hostname    = var.bootstrap_hostname
  bootstrap_ip          = var.bootstrap_ip
  master                = var.master
  master_hostnames      = var.master_hostnames
  master_ips            = var.master_ips
  worker                = var.worker
  worker_hostnames      = var.worker_hostnames
  worker_ips            = var.worker_ips
  storage               = var.storage
  storage_hostnames     = var.storage_hostnames
  storage_ips           = var.storage_ips
  helper                = var.helper
  helper_public_ip      = var.helper_public_ip
  helper_private_ip     = var.helper_private_ip
  ssh_private_key       = tls_private_key.installkey.private_key_pem
  network_device        = var.coreos_network_device
  cluster_id            = var.openshift_cluster_id
  base_domain           = var.openshift_base_domain
  private_netmask       = var.private_network_netmask
  private_gateway       = var.private_network_gateway
  openshift_nameservers = var.use_helper_for_node_dns ? [var.helper_private_ip] : var.public_network_nameservers

  vsphere_server               = var.vsphere_server
  vsphere_username             = var.vsphere_username
  vsphere_password             = var.vsphere_password
  vsphere_allow_insecure       = var.vsphere_allow_insecure
  vsphere_image_datastore      = var.vsphere_image_datastore
  vsphere_image_datastore_path = var.vsphere_image_datastore_path
}

module "ignition" {
  source = "./ignition"
  dependson = [
    module.createisos.module_completed
  ]
  helper              = var.helper
  helper_public_ip    = var.helper_public_ip
  ssh_private_key     = tls_private_key.installkey.private_key_pem
  ssh_public_key      = tls_private_key.installkey.public_key_openssh
  binaries            = var.binaries
  base_domain         = var.openshift_base_domain
  master              = var.master
  worker              = var.worker
  storage             = var.storage
  cluster_id          = var.openshift_cluster_id
  cluster_cidr        = var.openshift_cluster_cidr
  cluster_hostprefix  = var.openshift_host_prefix
  cluster_servicecidr = var.openshift_service_cidr
  vsphere_server      = var.vsphere_server
  vsphere_username    = var.vsphere_username
  vsphere_password    = var.vsphere_password
  vsphere_datacenter  = var.vsphere_datacenter
  vsphere_datastore   = var.vsphere_node_datastore
  pull_secret         = var.openshift_pull_secret
}

module "bootstrap" {
  source = "./bootstrap"
  dependson = [
    module.createisos.module_completed,
    module.ignition.module_completed
  ]
  vminfo               = var.bootstrap
  resource_pool_id     = var.preexisting_resource_pool ? data.vsphere_resource_pool.pool[0].id : vsphere_resource_pool.pool[0].id
  datastore_id         = data.vsphere_datastore.node.id
  image_datastore_id   = data.vsphere_datastore.images.id
  image_datastore_path = var.vsphere_image_datastore_path
  folder               = vsphere_folder.folder.path
  cluster_id           = var.openshift_cluster_id
  network_id           = data.vsphere_network.private.id
  helper               = var.helper
  helper_public_ip     = var.helper_public_ip
  ssh_private_key      = tls_private_key.installkey.private_key_pem
}

module "master" {
  source = "./nodes"
  dependson = [
    module.createisos.module_completed,
    module.ignition.module_completed,
    module.bootstrap.module_completed,
  ]
  vminfo               = var.master
  vmtype               = "master"
  resource_pool_id     = var.preexisting_resource_pool ? data.vsphere_resource_pool.pool[0].id : vsphere_resource_pool.pool[0].id
  datastore_id         = data.vsphere_datastore.node.id
  image_datastore_id   = data.vsphere_datastore.images.id
  image_datastore_path = var.vsphere_image_datastore_path
  folder               = vsphere_folder.folder.path
  cluster_id           = var.openshift_cluster_id
  network_id           = data.vsphere_network.private.id
  helper               = var.helper
  helper_public_ip     = var.helper_public_ip
  ssh_private_key      = tls_private_key.installkey.private_key_pem
}

module "worker" {
  source = "./nodes"
  dependson = [
    module.createisos.module_completed,
    module.ignition.module_completed,
    module.bootstrap.module_completed,
    #    module.master.module_completed,
  ]
  vminfo               = var.worker
  vmtype               = "worker"
  resource_pool_id     = var.preexisting_resource_pool ? data.vsphere_resource_pool.pool[0].id : vsphere_resource_pool.pool[0].id
  datastore_id         = data.vsphere_datastore.node.id
  image_datastore_id   = data.vsphere_datastore.images.id
  image_datastore_path = var.vsphere_image_datastore_path
  folder               = vsphere_folder.folder.path
  cluster_id           = var.openshift_cluster_id
  network_id           = data.vsphere_network.private.id
  helper               = var.helper
  helper_public_ip     = var.helper_public_ip
  ssh_private_key      = tls_private_key.installkey.private_key_pem
}

module "storage" {
  source = "./nodes"
  dependson = [
    module.createisos.module_completed,
    module.ignition.module_completed,
    module.bootstrap.module_completed,
    #    module.master.module_completed,
  ]
  vminfo               = var.storage
  vmtype               = "storage"
  resource_pool_id     = var.preexisting_resource_pool ? data.vsphere_resource_pool.pool[0].id : vsphere_resource_pool.pool[0].id
  datastore_id         = data.vsphere_datastore.node.id
  image_datastore_id   = data.vsphere_datastore.images.id
  image_datastore_path = var.vsphere_image_datastore_path
  folder               = vsphere_folder.folder.path
  cluster_id           = var.openshift_cluster_id
  network_id           = data.vsphere_network.private.id
  helper               = var.helper
  helper_public_ip     = var.helper_public_ip
  ssh_private_key      = tls_private_key.installkey.private_key_pem
}

module "deploy" {
  dependson = [
    module.createisos.module_completed,
    module.ignition.module_completed,
    module.master.module_completed,
    module.worker.module_completed,
    module.storage.module_completed
  ]
  source            = "./deploy"
  helper            = var.helper
  helper_public_ip  = var.helper_public_ip
  ssh_private_key   = tls_private_key.installkey.private_key_pem
  storage           = var.storage
  storage_hostnames = var.storage_hostnames
  cluster_id        = var.openshift_cluster_id
  base_domain       = var.openshift_base_domain
}

resource "vsphere_folder" "folder" {
  path          = var.openshift_cluster_id
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_resource_pool" "pool" {
  count                   = var.preexisting_resource_pool ? 0 : 1
  name                    = var.openshift_cluster_id
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
}

data "vsphere_resource_pool" "pool" {
  count         = var.preexisting_resource_pool ? 1 : 0
  name          = "/${var.vsphere_datacenter}/host/${var.vsphere_cluster}/Resources/${var.vsphere_resource_pool}"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
