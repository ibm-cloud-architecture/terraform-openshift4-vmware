locals {
  disks      = compact(list(var.disk_size, var.extra_disk_size == 0 ? "" : var.extra_disk_size))
  dual_homed = var.loadbalancer_network_id == "" ? false : true
  disk_sizes = zipmap(
    range(length(local.disks)),
    local.disks
  )
}
// dhcp_mac_addresses = var.dhcp_mac_addresses
data "template_file" "lb_ignition" {
  template = file("${path.module}/templates/ignition.tmpl")
  vars = {
    core_ssh_public_key = chomp(var.ssh_public_key)
    haproxy_file_config = base64encode(templatefile("${path.module}/templates/haproxy.tmpl", {
      lb_ip_address = var.lb_ip_address
      api           = var.api_backend_addresses
      ingress       = var.ingress_backend_addresses
    }))
    coredn_file_corefile = base64encode(templatefile("${path.module}/templates/Corefile.tmpl", {
      cluster_domain   = var.cluster_domain
      dns_addresses = join(" ", var.dns_addresses)
      machine_cidr   = var.machine_cidr
    }))
    coredn_file_clusterdb = base64encode(templatefile("${path.module}/templates/cluster.db.tmpl", {
      cluster_domain   = var.cluster_domain
      dns_ip_addresses = var.dns_ip_addresses
      lb_ip_address    = var.lb_ip_address
      machine_cidr   = var.machine_cidr
    }))
    dhcpd_file_conf = base64encode(templatefile("${path.module}/templates/dhcpd.tmpl", {
      dhcp_ip_addresses = var.dhcp_ip_addresses
      mac_prefix = var.mac_prefix
      machine_cidr   = var.machine_cidr
      cluster_domain = var.cluster_domain
      lb_ip_address    = var.lb_ip_address
    }))
    staticip_file_vm = base64encode(templatefile("${path.module}/templates/ifcfg.tmpl", {
      dns_addresses  = var.dns_addresses
      machine_cidr   = var.machine_cidr
      ip_address     = var.lb_ip_address
      cluster_domain = var.cluster_domain
      ens_device     = "ens192"
      prefix         = element(split("/", var.machine_cidr), 1)
      gateway        = "172.16.0.1"      
    }))
     dual_homed = local.dual_homed
     staticip_file_loadbalancer = base64encode(templatefile("${path.module}/templates/ifcfg.tmpl", {
       dns_addresses  = var.dns_addresses
       machine_cidr   = var.loadbalancer_cidr
       ip_address     = var.loadbalancer_ip
       cluster_domain = var.cluster_domain
       ens_device     = "ens224"
       prefix         = local.dual_homed ? element(split("/", var.machine_cidr), 1) : ""
       gateway        = "172.16.0.1"
      gateway        = local.dual_homed ? cidrhost(var.loadbalancer_cidr, 1) : ""
     }))
    hostname_file        = base64encode("lb-0")
    haproxy_systemd_unit = file("${path.module}/templates/haproxy.service")
    coredns_systemd_unit = file("${path.module}/templates/coredns.service")
    dhcpd_systemd_unit =   file("${path.module}/templates/dhcpd.service") 
  }
}

resource "vcd_vapp_vm" "loadbalancer" {

   for_each = var.hostnames_ip_addresses
 
   name = element(split(".", each.key), 0)


  vdc              = var.vcd_vdc
  org              = var.vcd_org
  cpus             = var.num_cpus
  memory           = var.memory
  vapp_name= var.app_name
  catalog_name= var.vcd_catalog
  template_name=var.lb_template
  power_on= true

  expose_hardware_virtualization = false # needs to be false for LB 



  network {
    type               = "org"
    name               = var.network_id
    ip                 = var.lb_ip_address
    ip_allocation_mode = "MANUAL"
    is_primary         = true
  }




 override_template_disk {
    bus_type           = "paravirtual"
    size_in_mb         = "250000"
    bus_number         = 0
    unit_number        = 0
}
  guest_properties = {
    "guestinfo.ignition.config.data"          = base64encode(data.ignition_config.ignition.rendered)
    "guestinfo.ignition.config.data.encoding" = "base64"
#    "guestinfo.afterburn.initrd.network-kargs" = "ip=${var.lb_ip_address}::${cidrhost(var.machine_cidr, 1)}:${cidrnetmask(var.machine_cidr)}:${element(split(".", each.key), 0)}:ens192:none ${join(" ", formatlist("nameserver=%v", var.dns_addresses))}"
  }
}


resource "local_file" "write_ignition" {
  content         = data.ignition_config.ignition.rendered
  filename        = "${path.cwd}/installer/${var.cluster_id}/lb_config.json"
  file_permission = 0600
}
