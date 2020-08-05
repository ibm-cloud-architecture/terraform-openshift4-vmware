resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependson)
  }
}

data "template_file" "install_config" {
  template = <<EOF
apiVersion: v1
baseDomain: ${var.base_domain}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: ${var.worker["count"] + var.storage["count"]}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${var.master["count"]}
metadata:
  name: ${var.cluster_id}
networking:
  clusterNetworks:
  - cidr: ${var.cluster_cidr}
    hostPrefix: ${var.cluster_hostprefix}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${var.cluster_servicecidr}
platform:
  vsphere:
    vCenter: ${var.vsphere_server}
    username: ${var.vsphere_username}
    password: ${var.vsphere_password}
    datacenter: ${var.vsphere_datacenter}
    defaultDatastore: ${var.vsphere_datastore}
pullSecret: '${file(var.pull_secret)}'
sshKey: '${var.ssh_public_key}'
EOF
}


resource "null_resource" "generate_ignition" {
  depends_on = [
    null_resource.dependency
  ]

  connection {
    host        = var.helper_public_ip
    user        = var.helper["username"]
    password    = var.helper["password"]
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    content     = data.template_file.install_config.rendered
    destination = "/tmp/install-config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir installer/",
      "cp /tmp/install-config.yaml installer/",
      "/usr/local/bin/openshift-install --dir=installer create manifests",
      "rm installer/openshift/99_openshift-cluster-api_master-machines*",
      "rm installer/openshift/99_openshift-cluster-api_worker-machineset*",
      "/usr/local/bin/openshift-install --dir=installer create ignition-configs",
      "sudo cp installer/*.ign /var/www/html/ignition/",
      "sudo chmod -R 644 /var/www/html/ignition/*.ign",
    ]
  }
}
