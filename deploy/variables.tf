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

variable "storage" {
  type = map(string)
  default = {
    count = "0"
  }
}

variable "storage_hostnames" {
  type    = list
  default = []
}

variable "cluster_id" {
  type = string
}

variable "base_domain" {
  type = string
}
