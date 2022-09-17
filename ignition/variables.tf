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

variable "control_plane_count" {
  type    = string
  default = "3"
}

variable "control_plane_memory" {
  type    = string
  default = "16384"
}

variable "control_plane_num_cpus" {
  type    = string
  default = "4"
}

variable "control_plane_disk_size" {
  type    = number
  default = 120
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

variable "worker_mtu" {
  type    = number
  default = 1500
}

variable "default_interface" {
  type    = string
  default = "ens192"
}

variable "ntp_server" {
  type    = string
  default = ""
}

variable "create_openshift_vips" {
  type    = bool
  default = true
}

variable "proxy_config" {
  type = map(string)
  default = {
    enabled    = false
    httpProxy  = ""
    httpsProxy = ""
    noProxy    = ""
  }
}

variable "trust_bundle" {
  type    = string
  default = ""
}

variable "airgapped" {
  type = map(string)
  default = {
    enabled    = false
    repository = ""
  }
}
