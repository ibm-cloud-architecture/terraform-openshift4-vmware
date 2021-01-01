locals {
  disks = compact(list(var.disk_size, var.extra_disk_size == 0 ? "" : var.extra_disk_size))
  disk_sizes = zipmap(
    range(length(local.disks)),
    local.disks
  )
}

resource "vcd_vapp_vm" "vm" {
  for_each = var.hostnames_ip_addresses

  name = element(split(".", each.key), 0)

#  resource_pool_id = var.resource_pool_id
#  datastore_id     = var.datastore_id

#  guest_id         = var.guest_id
##  folder           = var.folder_id
# nested_hv_enabled = var.nested_hv_enabled
#  enable_disk_uuid = "true"
  cpus             = var.num_cpus
  memory           = var.memory
  vdc              = var.vcd_vdc
  org              = var.vcd_org
  vapp_name= var.app_name
  catalog_name= var.vcd_catalog
  template_name=var.rhcos_template
  power_on= false

   network {
     type               = "org"
     name               = var.network_id
#    ip                 = "172.16.0.50"
     ip_allocation_mode = "NONE"
     is_primary         = true
   }
 
  override_template_disk {
    bus_type           = "paravirtual"
    size_in_mb         = "250000"
    bus_number         = 0
    unit_number        = 0
    iops               = 500
    storage_profile    = "4 IOPS/GB"  
}



  guest_properties = {
    "guestinfo.ignition.config.data"           = base64encode(var.ignition)
    "guestinfo.ignition.config.data.encoding"  = "base64"
    "guestinfo.afterburn.initrd.network-kargs" = "ip=${each.value}::${cidrhost(var.machine_cidr, 1)}:${cidrnetmask(var.machine_cidr)}:${element(split(".", each.key), 0)}:ens192:none ${join(" ", formatlist("nameserver=%v", var.dns_addresses))}"
  }
}
