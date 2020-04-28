variable "dependson" {
  type    = list(string)
  default = []
}

variable "vminfo" {
  type = map(string)
}

variable "datastore_id" {
  type = string
}

variable "resource_pool_id" {
  type = string
}

variable "image_datastore_id" {
  type = string
}

variable "image_datastore_path" {
  type = string
}

variable "folder" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "network_id" {
  type = string
}
