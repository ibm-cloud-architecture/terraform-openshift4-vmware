variable "vcd_vdc"     {
  type = string
}

variable "vcd_org"     {
  type = string
}

variable "app_name"    {
  type=string
}


variable "vcd_catalog"  {
  type = string
}

variable "lb_ip_address" {
  type = string
}

variable "lb_template" {
  type = string
}

variable "api_backend_addresses" {
  type = list(string)
}

variable "ingress_backend_addresses" {
  type = list(string)
}

variable "ssh_public_key" {
  type = string
}

variable "vm_dns_addresses" {
  type = list(string)
}

variable "bootstrap_ip" {
  type = string
}

variable "control_plane_ips" {
  type = list(string)
}

variable "dns_ip_addresses" {
  type = map(string)
}

variable "loadbalancer_ip" {
  type    = string
  default = ""
}

variable "loadbalancer_cidr" {
  type    = string
  default = ""
}

variable "external_dns_addresses" {
  type    = list(string)
  default = []
}

variable "loadbalancer_network_id" {
  type    = string
  default = ""
}

variable "hostnames_ip_addresses" {
  type = map(string)
}

variable "ignition" {
  type    = string
  default = ""
}

variable "dns_addresses" {
  type = list(string)
}

variable "dhcp_mac_addresses" {
  type = list(string)
}


variable "network_id" {
  type = string
}

variable "cluster_domain" {
  type = string
}


variable "machine_cidr" {
  type = string
}

variable "memory" {
  type    = number
  default = 4096
}

variable "num_cpus" {
  type    = number
  default = 2
}

variable "disk_size" {
  type    = number
  default = 60
}

variable "extra_disk_size" {
  type    = number
  default = 0
}

