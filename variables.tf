# VSPHERE CONNECTION INFORMATION
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
  type    = bool
  default = true
}
# ====================================

# VSPHERE INFRASTRUCTURE INFORMATION
variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_cluster" {
  type = string
}

variable "vsphere_image_datastore" {
  type        = string
  description = "Datastore where ISO images will be uploaded"
}

variable "vsphere_image_datastore_path" {
  type        = string
  description = "Path in vsphere_image_datastore where ISO images will be uploaded"
}

variable "vsphere_node_datastore" {
  type        = string
  description = "Datastore where OpenShift nodes will be deployed"
}

variable "vsphere_private_network" {
  type = string
}

variable "vsphere_public_network" {
  type    = string
  default = ""
}

variable "vsphere_folder" {
  type    = string
  default = ""
}

variable "vsphere_resource_pool" {
  type    = string
  default = ""
}
# ====================================


# URL FOR NEEDED BINARIES
variable "binaries" {
  type = map(string)
  default = {
    openshift_iso       = "https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.3/4.3.8/rhcos-4.3.8-x86_64-installer.x86_64.iso"
    openshift_bios      = "https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.3/4.3.8/rhcos-4.3.8-x86_64-metal.x86_64.raw.gz"
    openshift_kernel    = "https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.3/4.3.8/rhcos-4.3.8-x86_64-installer-kernel-x86_64"
    openshift_initramfs = "https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.3/4.3.8/rhcos-4.3.8-x86_64-installer-initramfs.x86_64.img"
    openshift_client    = "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.3.8/openshift-client-linux.tar.gz"
    openshift_installer = "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.3.8/openshift-install-linux.tar.gz"
    openshift_helper    = "https://github.com/RedHatOfficial/ocp4-helpernode"
    govc                = "https://github.com/vmware/govmomi/releases/download/v0.22.1/govc_linux_amd64.gz"
  }
}
# ====================================

# OPENSHIFT CONFIGURATION ITEMS
variable "openshift_cluster_id" {
  type = string
}

variable "openshift_base_domain" {
  type = string
}

variable "openshift_pull_secret" {
  type        = string
  description = "Local file with OCP4 pull secret"
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
# # ====================================


# # GENERAL VM NETWORK INFORMATION
variable "private_network_gateway" {
  type = string
}

variable "private_network_netmask" {
  type = string
}


variable "coreos_network_device" {
  type    = string
  default = "ens192"
}

variable "public_network_gateway" {
  type = string
}

variable "public_network_netmask" {
  type = string
}

variable "public_network_nameservers" {
  type = list(string)
}

variable "helper" {
  type = map(string)
  default = {
    template       = ""
    username       = ""
    password       = ""
    cpu            = ""
    memory         = ""
    disk           = ""
    network_device = ""
  }
}

variable "helper_public_ip" {
  type = string
}

variable "helper_private_ip" {
  type = string
}

variable "bootstrap" {
  type = map(string)
  default = {
    count  = 1
    cpu    = 4
    memory = 16
    disk   = 128
  }
}

variable "bootstrap_hostname" {
  type = string
}

variable "bootstrap_ip" {
  type = string
}

variable "master" {
  type = map(string)
  default = {
    count  = 3
    cpu    = 8
    memory = 32
    disk   = 128
  }
}
variable "master_hostnames" {
  type = list(string)
}

variable "master_ips" {
  type = list(string)
}

variable "worker" {
  type = map(string)
  default = {
    count  = 3
    cpu    = 8
    memory = 32
    disk   = 128
  }
}

variable "worker_hostnames" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}


variable "storage" {
  default = {
    count  = 0
    cpu    = 16
    memory = 64
    disk   = 128
  }
}

variable "storage_hostnames" {
  type    = list(string)
  default = []
}

variable "storage_ips" {
  type    = list(string)
  default = []
}

# if use_helper_for_node_dns == true, it will use var.helper_private_ip as its dns for all openshift nodes
# otherwise it will use var.public_network_nameservers for openshift node dns
variable "use_helper_for_node_dns" {
  type    = bool
  default = true
}
