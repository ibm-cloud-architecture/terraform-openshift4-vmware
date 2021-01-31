locals {
  disks = compact(list(var.disk_size, var.extra_disk_size == 0 ? "" : var.extra_disk_size))
  disk_sizes = zipmap(
    range(length(local.disks)),
    local.disks
  )
}



resource "vcd_vapp_vm" "storage" {
  //for_each = var.hostnames_ip_addresses

  //name = element(split(".", each.key), 0)
  
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
    size_in_mb         = "200000"
    bus_number         = 0
    unit_number        = 0
}



  guest_properties = {
    "guestinfo.ignition.config.data"           = base64encode(var.ignition)
    "guestinfo.ignition.config.data.encoding"  = "base64"
 }   
}
resource "vcd_vm_internal_disk" "disk1" {
   count = var.create_vms_only ? 0 : length(var.hostnames_ip_addresses)
   vm_name = element(split(".", keys(var.hostnames_ip_addresses)[count.index]), 0)
   vapp_name = var.app_name
   vdc              = var.vcd_vdc
   org              = var.vcd_org
   size_in_mb = var.extra_disk_size 
   bus_type           = "paravirtual"
   bus_number         = 0
   unit_number        = 1
   depends_on         = [vcd_vapp_vm.storage]
}

resource "vcd_vapp_vm" "storage-vm-only" {
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
    size_in_mb         = "200000"
    bus_number         = 0
    unit_number        = 0
  }
}
resource "vcd_vm_internal_disk" "disk1-vm-only" {
   count = var.create_vms_only ? length(var.hostnames_ip_addresses) : 0
   vm_name = element(split(".", keys(var.hostnames_ip_addresses)[count.index]), 0)
   vapp_name = var.app_name
   vdc              = var.vcd_vdc
   org              = var.vcd_org
   size_in_mb = var.extra_disk_size 
   bus_type           = "paravirtual"
   bus_number         = 0
   unit_number        = 1
   depends_on         = [vcd_vapp_vm.storage-vm-only]
}