variable "base_domain" {
  type = string
}

variable "cluster_cidr" {
  type = string
}

variable "cluster_hostprefix" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_servicecidr" {
  type = string
}

variable "machine_cidr" {
  type = string
}

variable "master_cpu" {
  type    = string
  default = 8
}

variable "master_disk_size" {
  type    = string
  default = 120
}

variable "master_memory" {
  type    = string
  default = 32768
}

variable "pull_secret" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "vsphere_password" {
  type = string
}

variable "vsphere_server" {
  type = string
}

variable "vsphere_network" {
  type = string
}

variable "vsphere_cluster" {
  type = string
}

variable "vsphere_username" {
  type = string
}

variable "vsphere_folder" {
  type = string
}

variable "openshift_version" {
  type = string
}

variable "total_node_count" {
  type = number
}

variable "api_vip" {
  type = string
}

variable "ingress_vip" {
  type = string
}
