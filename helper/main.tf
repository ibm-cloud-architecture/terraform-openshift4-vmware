data "vsphere_virtual_machine" "template" {
  name          = var.vminfo["template"]
  datacenter_id = var.datacenter_id
}

resource "vsphere_virtual_machine" "helper" {
  name             = "${var.cluster_id}-helper"
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder_id

  num_cpus = var.vminfo["cpu"]
  memory   = var.vminfo["memory"]
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  dynamic "network_interface" {
    for_each = compact(concat(list(var.public_network_id, var.private_network_id)))
    content {
      network_id   = network_interface.value
      adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    }
  }

  disk {
    label            = "disk0"
    size             = var.vminfo["disk"]
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.cluster_id}-helper"
        domain    = "${var.cluster_id}.${var.base_domain}"
      }

      dynamic "network_interface" {
        for_each = compact(concat(list(var.public_ip, var.private_ip)))
        content {
          ipv4_address = network_interface.value
          ipv4_netmask = element(compact(concat(list(var.public_netmask), list(var.private_netmask))), network_interface.key)
        }
      }

      ipv4_gateway    = var.public_gateway != "" ? var.public_gateway : var.private_gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = ["${var.cluster_id}.${var.base_domain}"]
    }
  }

  connection {
    host        = var.public_ip
    user        = var.vminfo["username"]
    password    = var.vminfo["password"]
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/tmp/terraform_scripts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod u+x /tmp/terraform_scripts/*.sh",
      "/tmp/terraform_scripts/add-private-ssh-key.sh \"${var.ssh_private_key}\" \"${var.vminfo["username"]}\"",
      "/tmp/terraform_scripts/add-public-ssh-key.sh \"${var.ssh_public_key}\""
    ]
  }
}

data "template_file" "inventory" {
  template = <<EOF
---
ssh_gen_key: false
staticips: true
helper:
  name: "helper"
  ipaddr: "${var.private_ip}"
  networkifacename: "${var.vminfo["network_device"]}"
dns:
  domain: "${var.base_domain}"
  clusterid: "${var.cluster_id}"
  forwarder1: "${var.dns_servers[0]}"
  forwarder2: "${var.dns_servers[1]}"
bootstrap:
  name: "${var.bootstrap_hostname}"
  ipaddr: "${var.bootstrap_ip}"
masters:
${join("\n", formatlist("  - name: %v\n    ipaddr: %v", var.master_hostnames, var.master_ips))}
workers:
${join("\n", formatlist("  - name: %v\n    ipaddr: %v", var.worker_hostnames, var.worker_ips))}
${join("\n", formatlist("  - name: %v\n    ipaddr: %v", var.storage_hostnames, var.storage_ips))}
ocp_bios: "${var.binaries["openshift_bios"]}"
ocp_initramfs: "${var.binaries["openshift_initramfs"]}"
ocp_install_kernel: "${var.binaries["openshift_kernel"]}"
ocp_client: "${var.binaries["openshift_client"]}"
ocp_installer: "${var.binaries["openshift_installer"]}"
EOF
}

resource "null_resource" "configure" {
  triggers = {
    master_hostnames  = join(",", var.master_hostnames)
    master_ips        = join(",", var.master_ips)
    worker_hostnames  = join(",", var.worker_hostnames)
    worker_ips        = join(",", var.worker_ips)
    storage_hostnames = join(",", var.storage_hostnames)
    storage_ips       = join(",", var.storage_ips)
  }

  depends_on = [
    vsphere_virtual_machine.helper
  ]

  connection {
    host        = var.public_ip
    user        = var.vminfo["username"]
    password    = var.vminfo["password"]
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      "sudo yum install epel-release -y",
      "sudo yum install git ansible genisoimage -y",
      "test -e /tmp/ocp4-helpernode || git clone ${var.binaries["openshift_helper"]} /tmp/ocp4-helpernode",
      "curl -sL -o /tmp/govc.gz ${var.binaries["govc"]}",
      "gunzip /tmp/govc.gz",
      "chmod 755 /tmp/govc",
      "sudo mv /tmp/govc /usr/local/bin/"
    ]
  }

  provisioner "file" {
    content     = data.template_file.inventory.rendered
    destination = "/tmp/ocp4-helpernode/vars.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/ocp4-helpernode",
      "sudo ansible-playbook -e @vars.yaml tasks/main.yml"
    ]
  }
}
