locals {
  disks = compact(list(var.disk_size, var.extra_disk_size == 0 ? "" : var.extra_disk_size))
  disk_sizes = zipmap(
    range(length(local.disks)),
    local.disks
  )
}

resource "vsphere_virtual_machine" "vm" {
  for_each = var.hostnames_ip_addresses

  name = element(split(".", each.key), 0)

  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  num_cpus         = var.num_cpus
  memory           = var.memory
  guest_id         = var.guest_id
  folder           = var.folder_id
  enable_disk_uuid = "true"

  dynamic "disk" {
    for_each = local.disk_sizes
    content {
      label            = "disk${disk.key}"
      size             = disk.value
      thin_provisioned = var.disk_thin_provisioned
      unit_number      = disk.key
    }
  }

  wait_for_guest_net_timeout  = "0"
  wait_for_guest_net_routable = "false"

  nested_hv_enabled = var.nested_hv_enabled

  network_interface {
    network_id = var.network_id
  }

  clone {
    template_uuid = var.template_uuid
  }

  extra_config = {
    "guestinfo.ignition.config.data"           = base64encode(var.ignition)
    "guestinfo.ignition.config.data.encoding"  = "base64"
    "guestinfo.afterburn.initrd.network-kargs" = "ip=${each.value}::${var.vm_gateway}:${cidrnetmask(var.machine_cidr)}:${element(split(".", each.key), 0)}:ens192:none ${join(" ", formatlist("nameserver=%v", var.dns_addresses))}"
  }
}
