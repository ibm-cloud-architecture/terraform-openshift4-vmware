//////
// vSphere variables
//////

variable "vsphere_server" {
  type        = string
  description = "This is the vSphere server for the environment."
}

variable "vsphere_user" {
  type        = string
  description = "vSphere server user for the environment."
}

variable "vsphere_password" {
  type        = string
  description = "vSphere server password"
}

variable "vsphere_cluster" {
  type        = string
  description = "This is the name of the vSphere cluster."
}

variable "vsphere_datacenter" {
  type        = string
  description = "This is the name of the vSphere data center."
}

variable "vsphere_datastore" {
  type        = string
  description = "This is the name of the vSphere data store."
}

variable "vm_template" {
  type        = string
  description = "This is the name of the VM template to clone."
}

variable "vm_network" {
  type        = string
  description = "This is the name of the publicly accessible network for cluster ingress and access."
  default     = "VM Network"
}

variable "vm_dns_addresses" {
  type        = list(string)
  description = "List of DNS servers to use for your OpenShift Nodes"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "vm_gateway" {
  type        = string
  description = "IP Address to use for VM default gateway.  If not set, default is the first host in the CIDR range"
  default     = null
}

variable "vsphere_preexisting_folder" {
  type        = bool
  description = "If false, creates a top-level folder with the name from vsphere_folder_rel_path."
  default     = false
}

variable "vsphere_folder" {
  type        = string
  description = "The relative path to the folder which should be used or created for VMs."
  default     = ""
}

variable "vsphere_preexisting_resourcepool" {
  description = "If false, creates a resource pool for OpenShift nodes."
  default     = false
}

variable "vsphere_resource_pool" {
  type        = string
  description = "The resource pool that should be used or created for VMs"
  default     = ""
}

/////////
// OpenShift cluster variables
/////////

variable "cluster_id" {
  type        = string
  description = "This cluster id must be of max length 27 and must have only alphanumeric or hyphen characters."
}

variable "base_domain" {
  type        = string
  description = "The base DNS zone to add the sub zone to."
}

variable "machine_cidr" {
  type = string
}

/////////
// Bootstrap machine variables
/////////
variable "bootstrap_ip_address" {
  type    = string
  default = ""
}

///////////
// control-plane machine variables
///////////

variable "control_plane_count" {
  type    = string
  default = "3"
}

variable "control_plane_ip_addresses" {
  type    = list(string)
  default = []
}

variable "control_plane_name" {
  type    = string
  default = "control-plane"
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

variable "control_plane_extra_disk_size" {
  type    = number
  default = 0 
}

//////////
// compute machine variables
//////////

variable "compute_count" {
  type    = string
  default = "3"
}

variable "compute_ip_addresses" {
  type    = list(string)
  default = []
}

variable "compute_name" {
  type    = string
  default = "compute"
}

variable "compute_memory" {
  type    = string
  default = "8192"
}

variable "compute_num_cpus" {
  type    = string
  default = "2"
}

variable "compute_disk_size" {
  type    = number
  default = 120
}

variable "compute_extra_disk_size" {
  type    = number
  default = 0 
}

//////////
// infra machine variables
//////////

variable "infra_count" {
  type    = string
  default = "0"
}

variable "infra_ip_addresses" {
  type    = list(string)
  default = []
}

variable "infra_name" {
  type    = string
  default = "infra"
}

variable "infra_memory" {
  type    = string
  default = "8192"
}

variable "infra_num_cpus" {
  type    = string
  default = "2"
}

variable "infra_disk_size" {
  type    = number
  default = 120
}

variable "infra_extra_disk_size" {
  type    = number
  default = 0 
}

//////////
// storage machine variables
//////////

variable "storage_count" {
  type    = string
  default = "0"
}

variable "storage_ip_addresses" {
  type    = list(string)
  default = []
}

variable "storage_name" {
  type    = string
  default = "storage"
}

variable "storage_memory" {
  type    = string
  default = "65536"
}

variable "storage_num_cpus" {
  type    = string
  default = "16"
}

variable "storage_disk_size" {
  type    = number
  default = 120
}

variable "storage_extra_disk_size" {
  type    = number
  default = 0 
}

variable "storage_additional_disk_size" {
  type    = number
  default = 0 
}

variable "openshift_api_virtualip" {
  type        = string
  description = "Virtual IP used to access the cluster API."
}

variable "openshift_ingress_virtualip" {
  type        = string
  description = "Virtual IP used for cluster ingress traffic."
}

variable "openshift_pull_secret" {
  type = string
}

variable "openshift_cluster_cidr" {
  type    = string
  default = "10.128.0.0/14"
}

variable "openshift_service_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "openshift_host_prefix" {
  type    = string
  default = 23
}

variable "openshift_version" {
  type        = string
  description = "Specify the OpenShift version you want to deploy.  Must be 4.6 or later to use this automation"
  default     = "4.6.16"
}

variable "create_openshift_vips" {
  type = bool
  # https://github.com/openshift/installer/blob/master/docs/user/vsphere/vips-dns.md
  description = "Deploy OpenShift with self contained LoadBalancer"
  default     = true
}

variable "ssh_public_key" {
  type        = string
  description = "Path to your ssh public key.  If left blank we will generate one."
  default     = ""
}

variable "openshift_worker_mtu" {
  type        = number
  description = "The NIC MTU to be used for compute OpenShift VMs"
  default     = 1500
}

variable "openshift_ntp_server" {
  type    = string
  default = ""
}

variable "bootstrap_complete" {
  type    = string
  default = "false"
}
