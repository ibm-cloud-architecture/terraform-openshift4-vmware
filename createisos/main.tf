resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependson)
  }
}

locals {
  all_hostnames = concat(list(var.bootstrap_hostname), var.master_hostnames, var.worker_hostnames, var.storage_hostnames)
  all_ips       = concat(list(var.bootstrap_ip), var.master_ips, var.worker_ips, var.storage_ips)
  all_count     = 1 + var.master["count"] + var.worker["count"] + var.storage["count"]
  all_type = concat(
    data.template_file.bootstrap_type.*.rendered,
    data.template_file.master_type.*.rendered,
    data.template_file.worker_type.*.rendered,
    data.template_file.storage_type.*.rendered,
  )
  all_index = concat(
    data.template_file.bootstrap_index.*.rendered,
    data.template_file.master_index.*.rendered,
    data.template_file.worker_index.*.rendered,
    data.template_file.storage_index.*.rendered,
  )
}

data "template_file" "bootstrap_type" {
  count    = 1
  template = "bootstrap"
}

data "template_file" "master_type" {
  count    = var.master["count"]
  template = "master"
}

data "template_file" "worker_type" {
  count    = var.worker["count"]
  template = "worker"
}

data "template_file" "storage_type" {
  count    = var.storage["count"]
  template = "worker"
}

data "template_file" "bootstrap_index" {
  count    = 1
  template = count.index + 1
}

data "template_file" "master_index" {
  count    = var.master["count"]
  template = count.index + 1
}

data "template_file" "worker_index" {
  count    = var.worker["count"]
  template = count.index + 1
}

data "template_file" "storage_index" {
  count    = var.storage["count"]
  template = count.index + 1 + var.worker["count"]
}


resource "null_resource" "downloadiso" {
  depends_on = [
    null_resource.dependency
  ]

  connection {
    host        = var.helper_public_ip
    user        = var.helper["username"]
    password    = var.helper["password"]
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sL -o /tmp/installer.iso ${var.binaries["openshift_iso"]}",
      "test -e /tmp/tempiso || mkdir /tmp/tempiso",
      "sudo mount /tmp/installer.iso /tmp/tempiso",
      "test -e /tmp/iso || mkdir /tmp/iso",
      "cp -r /tmp/tempiso/* /tmp/iso/",
      "sudo umount /tmp/tempiso",
      "sudo chmod -R u+w /tmp/iso/",
      "sed -i 's/default vesamenu.c32/default linux/g' /tmp/iso/isolinux/isolinux.cfg"
    ]
  }
}

locals {
  coreos_netmask = cidrnetmask("${var.helper_private_ip}/${var.private_netmask}")
  nameservers    = join(" ", formatlist("nameserver=%v", var.openshift_nameservers))
}

resource "null_resource" "generateisos" {
  triggers = {
    master_hostnames  = join(",", var.master_hostnames)
    master_ips        = join(",", var.master_ips)
    worker_hostnames  = join(",", var.worker_hostnames)
    worker_ips        = join(",", var.worker_ips)
    storage_hostnames = join(",", var.storage_hostnames)
    storage_ips       = join(",", var.storage_ips)

  }
  count = local.all_count
  depends_on = [
    null_resource.downloadiso
  ]

  connection {
    host        = var.helper_public_ip
    user        = var.helper["username"]
    password    = var.helper["password"]
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cp -Rp /tmp/iso /tmp/${local.all_hostnames[count.index]}",
      "sed -i 's/coreos.inst=yes/coreos.inst=yes ip=${local.all_ips[count.index]}::${var.private_gateway}:${local.coreos_netmask}:${local.all_hostnames[count.index]}.${var.cluster_id}.${var.base_domain}:${var.network_device}:none ${local.nameservers} coreos.inst.install_dev=sda coreos.inst.image_url=http:\\/\\/${var.helper_private_ip}:8080\\/install\\/bios.raw.gz coreos.inst.ignition_url=http:\\/\\/${var.helper_private_ip}:8080\\/ignition\\/${local.all_type[count.index]}.ign/g' /tmp/${local.all_hostnames[count.index]}/isolinux/isolinux.cfg",
      "mkisofs -o /tmp/${var.cluster_id}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso -rational-rock -J -joliet-long -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table /tmp/${local.all_hostnames[count.index]} > /dev/null 2>&1",
      "export GOVC_URL=${var.vsphere_server}",
      "export GOVC_USERNAME=${var.vsphere_username}",
      "export GOVC_PASSWORD=${var.vsphere_password}",
      "export GOVC_INSECURE=${var.vsphere_allow_insecure}",
      "govc datastore.upload -ds=${var.vsphere_image_datastore} /tmp/${var.cluster_id}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso ${var.vsphere_image_datastore_path}/${var.cluster_id}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso  > /dev/null 2>&1"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "export GOVC_URL=${var.vsphere_server}",
      "export GOVC_USERNAME=${var.vsphere_username}",
      "export GOVC_PASSWORD=${var.vsphere_password}",
      "export GOVC_INSECURE=${var.vsphere_allow_insecure}",
      "govc datastore.rm -ds=${var.vsphere_image_datastore} ${var.vsphere_image_datastore_path}/${var.cluster_id}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso  > /dev/null 2>&1"
    ]
  }
}
