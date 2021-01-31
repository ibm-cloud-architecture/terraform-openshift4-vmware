locals {
  disks = compact(list(var.disk_size, var.extra_disk_size == 0 ? "" : var.extra_disk_size))
  disk_sizes = zipmap(
    range(length(local.disks)),
    local.disks
  )
  temp_var = zipmap([],[])
}



resource "vcd_vapp_vm" "vm" {
  count = var.create_vms_only ? 0 : length(var.hostnames_ip_addresses)
  name = element(split(".", keys(var.hostnames_ip_addresses)[count.index]), 0)

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
     ip_allocation_mode = "DHCP"
     mac                 = "${var.mac_prefix}:${element(split(".",values(var.hostnames_ip_addresses)[count.index]),3)}"
    is_primary         = true
   }
 
  override_template_disk {
    bus_type           = "paravirtual"
    size_in_mb         = var.disk_size
    bus_number         = 0
    unit_number        = 0
}


  guest_properties = {
    "guestinfo.ignition.config.data"           = base64encode(var.ignition)
    "guestinfo.ignition.config.data.encoding"  = "base64"
 }   
}

resource "vcd_vapp_vm" "vm-only" {
  count = var.create_vms_only ? length(var.hostnames_ip_addresses) : 0

  name = element(split(".", keys(var.hostnames_ip_addresses)[count.index]), 0)

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
     ip_allocation_mode = "DHCP"
     mac                 = "${var.mac_prefix}:${element(split(".",values(var.hostnames_ip_addresses)[count.index]),3)}"
    is_primary         = true
   }
 
  override_template_disk {
    bus_type           = "paravirtual"
    size_in_mb         = var.disk_size
    bus_number         = 0
    unit_number        = 0
  }
 
}