variable "dependson" {
  type    = list(string)
  default = []
}

variable "bootstrap" {
  type = map(string)
}

variable "bootstrap_hostname" {
  type = string
}

variable "bootstrap_ip" {
  type = string
}

variable "master" {
  type = map(string)
}

variable "master_hostnames" {
  type = list(string)
}

variable "master_ips" {
  type = list(string)
}

variable "worker" {
  type = map(string)
}

variable "worker_hostnames" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "storage" {
  type = map(string)
}

variable "storage_hostnames" {
  type = list(string)
}

variable "storage_ips" {
  type = list(string)
}

variable "helper" {
  type = map(string)
}

variable "helper_public_ip" {
  type = string
}

variable "helper_private_ip" {
  type = string
}

variable "ssh_private_key" {
  type = string
}

variable "binaries" {
  type = map(string)
}

variable "network_device" {
  type = string
}

variable "cluster_id" {
  type = string
}
variable "base_domain" {
  type = string
}

variable "private_netmask" {
  type = string
}

variable "private_gateway" {
  type = string
}
variable "vsphere_server" {
  type = string
}

variable "vsphere_username" {
  type = string
}

variable "vsphere_password" {
  type = string
}

variable "vsphere_allow_insecure" {
  type = string
}

variable "vsphere_image_datastore" {
  type = string
}

variable "vsphere_image_datastore_path" {
  type = string
}

variable "openshift_nameservers" {
  type = list
}
