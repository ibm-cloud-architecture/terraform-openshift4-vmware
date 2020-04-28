variable "datacenter_id" {
  type = string
}

variable "datastore_id" {
  type = string
}

variable "resource_pool_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "public_network_id" {
  type = string
}

variable "private_network_id" {
  type = string
}

variable "vminfo" {
  type = map(string)
}

variable "private_ip" {
  type = string
}

variable "public_ip" {
  type = string
}

variable "public_gateway" {
  type = string
}

variable "private_gateway" {
  type = string
}

variable "public_netmask" {
  type = string
}

variable "private_netmask" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "dns_servers" {
  type = list(string)
}

variable "ssh_private_key" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "bootstrap_hostname" {
  type = string
}

variable "bootstrap_ip" {
  type = string
}

variable "master_hostnames" {
  type = list(string)
}

variable "master_ips" {
  type = list(string)
}

variable "worker_hostnames" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "storage_hostnames" {
  type = list(string)
}

variable "storage_ips" {
  type = list(string)
}

variable "binaries" {
  type = map(string)
}
