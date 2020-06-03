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

variable "master_hostnames" {
  type = list(string)
}

variable "worker_hostnames" {
  type = list(string)
}

variable "storage_hostnames" {
  type = list(string)
}

variable "apps_certificate" {
  type    = string
  default = null
}

variable "apps_certificate_key" {
  type    = string
  default = null
}

variable "api_certificate" {
  type    = string
  default = null
}

variable "api_certificate_key" {
  type    = string
  default = null
}

variable "custom_ca_bundle" {
  type    = string
  default = null
}

variable "cluster_id" {
  type    = string
  default = null
}

variable "base_domain" {
  type    = string
  default = null
}
