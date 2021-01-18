locals {
  disks = compact(list(var.disk_size, var.extra_disk_size == 0 ? "" : var.extra_disk_size))
  disk_sizes = zipmap(
    range(length(local.disks)),
    local.disks
  )
}



resource "vcd_vapp_vm" "vm" {
  for_each = var.hostnames_mac_addresses

  name = element(split(".", each.key), 0)

  cpus             = var.num_cpus
  memory           = var.memory
  vdc              = var.vcd_vdc
  org              = var.vcd_org
#  hardware_version = "vmx-14"
  vapp_name= var.app_name
  catalog_name= var.vcd_catalog
  template_name=var.rhcos_template
  power_on= false

   network {
     type               = "org"
     name               = var.network_id
     ip_allocation_mode = "DHCP"
    mac                 = each.value
    is_primary         = true
   }
 
  override_template_disk {
    bus_type           = "paravirtual"
    size_in_mb         = var.disk_size
    bus_number         = 0
    unit_number        = 0
    iops               = 500
    storage_profile    = "4 IOPS/GB"  
}


  guest_properties = {
    "guestinfo.ignition.config.data"           = base64encode(var.ignition)
    "guestinfo.ignition.config.data.encoding"  = "base64"
 #   "disk.EnableUUID"                          = "TRUE" 
 }   
}
