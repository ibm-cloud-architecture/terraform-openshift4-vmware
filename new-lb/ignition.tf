data "ignition_file" "haproxy_config" {
  path = "/etc/haproxy/haproxy.conf"
  mode = 420
  content {
    content = templatefile("${path.module}/templates/haproxy.tmpl", {
      lb_ip_address = var.lb_ip_address
      api           = var.api_backend_addresses
      ingress       = var.ingress_backend_addresses
    })
  }
}

data "ignition_file" "coredns_corefile" {
  path = "/etc/coredns/Corefile"
  mode = 420
  content {
    content = templatefile("${path.module}/templates/Corefile.tmpl", {
      cluster_domain   = var.cluster_domain
      vm_dns_addresses = join(" ", var.vm_dns_addresses)
    })
  }
}

data "ignition_file" "dhcpd_conf" {
  path = "/etc/dhcpd/dhcpd.conf"
  mode = 420
  content {
    content = templatefile("${path.module}/templates/dhcpd.tmpl", {
    dhcp_nodes = var.dhcp_nodes
    })
  }
}
data "ignition_file" "coredns_clusterdb" {
  path = "/etc/coredns/cluster.db"
  mode = 420
  content {
    content = templatefile("${path.module}/templates/cluster.db.tmpl", {
      cluster_domain   = var.cluster_domain
      dns_ip_addresses = var.dns_ip_addresses
      lb_ip_address    = var.lb_ip_address
    })
  }
}

data "ignition_file" "hostname" {
  path = "/etc/hostname"
  mode = "420"

  content {
    content = "lb-0"
  }
}

data "ignition_file" "static_ip" {
  path = "/etc/sysconfig/network-scripts/ifcfg-ens192"
  mode = "420"

  content {
    content = templatefile("${path.module}/templates/ifcfg.tmpl", {
      dns_addresses  = var.vm_dns_addresses
      machine_cidr   = var.machine_cidr
      ip_address     = var.lb_ip_address
      cluster_domain = var.cluster_domain
      ens_device     = "ens192"
      prefix         = element(split("/", var.machine_cidr), 1)
#      gateway        = local.dual_homed ? "" : cidrhost(var.machine_cidr, 1)
      gateway        = cidrhost(var.machine_cidr, 1)
    })
  }
}


data "ignition_file" "static_ip_loadbalancer" {
  count = local.dual_homed ? 1 : 0
  path  = "/etc/sysconfig/network-scripts/ifcfg-ens224"
  mode  = "420"

  content {
    content = templatefile("${path.module}/templates/ifcfg.tmpl", {
      dns_addresses  = var.vm_dns_addresses
      machine_cidr   = var.loadbalancer_cidr
      ip_address     = var.loadbalancer_ip
      cluster_domain = var.cluster_domain
      ens_device     = "ens224"
      prefix         = element(split("/", var.machine_cidr), 1)
      gateway        = cidrhost(var.loadbalancer_cidr, 1)
    })
  }
}

data "ignition_systemd_unit" "haproxy" {
  name    = "haproxy.service"
  content = file("${path.module}/templates/haproxy.service")
}

data "ignition_systemd_unit" "coredns" {
  name    = "coredns.service"
  content = file("${path.module}/templates/coredns.service")
}

data "ignition_systemd_unit" "dhcpd" {
  name    = "dhcpd.service"
  content = file("${path.module}/templates/dhcpd.service")
}
data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = [chomp(var.ssh_public_key)]
}


data "ignition_config" "ignition" {
  users = [
    data.ignition_user.core.rendered,
  ]
  files = [
    data.ignition_file.haproxy_config.rendered,
    data.ignition_file.coredns_corefile.rendered,
    data.ignition_file.coredns_clusterdb.rendered,
    data.ignition_file.dhcpd_conf.rendered,    
    data.ignition_file.hostname.rendered,
    data.ignition_file.static_ip.rendered,
    local.dual_homed ? data.ignition_file.static_ip_loadbalancer[0].rendered : ""
  ]
  systemd = [
    data.ignition_systemd_unit.haproxy.rendered,
    data.ignition_systemd_unit.coredns.rendered,
    data.ignition_systemd_unit.dhcpd.rendered

  ]
}

