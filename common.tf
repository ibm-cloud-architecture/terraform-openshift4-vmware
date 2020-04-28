data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "node" {
  name          = var.vsphere_node_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "images" {
  name          = var.vsphere_image_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "public" {
  name          = var.vsphere_public_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "private" {
  name          = var.vsphere_private_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

locals {
  all_hostnames = concat(list(var.bootstrap_hostname), var.master_hostnames, var.worker_hostnames, var.storage_hostnames)
  all_ips       = concat(list(var.bootstrap_ip), var.master_ips, var.worker_ips, var.storage_ips)
  all_count     = 1 + var.master["count"] + var.worker["count"] + var.storage["count"]
  all_type = concat(
    data.template_file.bootstrap_type.*.rendered,
    data.template_file.master_type.*.rendered,
    data.template_file.worker_type.*.rendered,
    data.template_file.storage_type.*.rendered,
  )
  all_index = concat(
    data.template_file.bootstrap_index.*.rendered,
    data.template_file.master_index.*.rendered,
    data.template_file.worker_index.*.rendered,
    data.template_file.storage_index.*.rendered,
  )

  all_hostnames_no_bootstrap = concat(var.master_hostnames, var.worker_hostnames, var.storage_hostnames)
  all_ips_no_bootstrap       = concat(var.master_ips, var.worker_ips, var.storage_ips)
  all_count_no_bootstrap     = var.master["count"] + var.worker["count"] + var.storage["count"]
  all_type_no_bootstrap = concat(
    data.template_file.master_type.*.rendered,
    data.template_file.worker_type.*.rendered,
    data.template_file.storage_type.*.rendered,
  )
  all_index_no_bootstrap = concat(
    data.template_file.master_index.*.rendered,
    data.template_file.worker_index.*.rendered,
    data.template_file.storage_index.*.rendered,
  )
}

data "template_file" "bootstrap_type" {
  count    = 1
  template = "bootstrap"
}

data "template_file" "master_type" {
  count    = var.master["count"]
  template = "master"
}

data "template_file" "worker_type" {
  count    = var.worker["count"]
  template = "worker"
}

data "template_file" "storage_type" {
  count    = var.storage["count"]
  template = "worker"
}

data "template_file" "bootstrap_index" {
  count    = 1
  template = count.index + 1
}

data "template_file" "master_index" {
  count    = var.master["count"]
  template = count.index + 1
}

data "template_file" "worker_index" {
  count    = var.worker["count"]
  template = count.index + 1
}

data "template_file" "storage_index" {
  count    = var.storage["count"]
  template = count.index + 1 + var.worker["count"]
}
