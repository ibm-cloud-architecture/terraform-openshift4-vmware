variable "dependson" {
  type    = list(string)
  default = []
}

variable "helper" {
  type = map(string)
}

variable "helper_public_ip" {
  type = string
}

variable "ssh_private_key" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "binaries" {
  type = map(string)
}

variable "base_domain" {
  type = string
}

variable "master" {
  type = map(string)
}

variable "worker" {
  type = map(string)
}

variable "storage" {
  type = map(string)
}

variable "cluster_id" {
  type = string
}

variable "cluster_cidr" {
  type = string
}

variable "cluster_hostprefix" {
  type = string
}

variable "cluster_servicecidr" {
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

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "pull_secret" {
  type = string
}
