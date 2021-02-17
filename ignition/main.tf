data "template_file" "install_config" {
  template = <<EOF
apiVersion: v1
baseDomain: ${var.base_domain}
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    vsphere:
      coresPerSocket: 1
      cpus: ${var.master_cpu}
      memoryMB: ${var.master_memory}
      osDisk:
        diskSizeGB: ${var.master_disk_size}
  replicas: 3
metadata:
  name: ${var.cluster_id}
networking:
  clusterNetwork:
  - cidr: ${var.cluster_cidr}
    hostPrefix: ${var.cluster_hostprefix}
  machineNetwork:
  - cidr: ${var.machine_cidr}
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
    network: ${var.vsphere_network}
    cluster: ${var.vsphere_cluster}
%{if var.vsphere_folder != ""}    folder: /${var.vsphere_datacenter}/vm/${var.vsphere_folder}%{endif}
%{if var.api_vip != ""}    apiVIP: ${var.api_vip}%{endif}
%{if var.ingress_vip != ""}    ingressVIP: ${var.ingress_vip}%{endif}
pullSecret: '${chomp(file(var.pull_secret))}'
sshKey: '${var.ssh_public_key}'
EOF
}


data "template_file" "cluster_scheduler" {
  template = <<EOF
apiVersion: config.openshift.io/v1
kind: Scheduler
metadata:
  creationTimestamp: null
  name: cluster
spec:
  mastersSchedulable: false
  policy:
    name: ""
status: {}
EOF
}

data "template_file" "post_deployment_05" {
  template = templatefile("${path.module}/templates/99_05-post-deployment.yaml", {
    csr_common_secret  = base64encode(file("${path.module}/templates/common.sh"))
    csr_approve_secret = base64encode(file("${path.module}/templates/approve-csrs.sh"))
  })
}

data "template_file" "post_deployment_06" {
  template = templatefile("${path.module}/templates/99_06-post-deployment.yaml", {
    node_count = var.total_node_count
  })
}

locals {
  installerdir = "${path.root}/installer/${var.cluster_id}"
}

resource "null_resource" "download_binaries" {
  provisioner "local-exec" {
    command = <<EOF
set -ex
test -e ${local.installerdir} || mkdir -p ${local.installerdir}
if [[ $(uname -s) == "Darwin" ]]; then PLATFORM="mac"; else PLATFORM="linux"; fi
curl -o ${local.installerdir}/openshift-installer.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${var.openshift_version}/openshift-install-$PLATFORM.tar.gz
tar -xf ${local.installerdir}/openshift-installer.tar.gz -C ${local.installerdir}
EOF
  }
}

resource "local_file" "install_config_yaml" {
  content  = data.template_file.install_config.rendered
  filename = "${local.installerdir}/install-config.yaml"
  depends_on = [
    null_resource.download_binaries,
  ]
}

resource "null_resource" "generate_manifests" {
  provisioner "local-exec" {
    command = <<EOF
set -ex
${local.installerdir}/openshift-install --dir=${local.installerdir}/ create manifests --log-level debug
rm ${local.installerdir}/openshift/99_openshift-cluster-api_master-machines*
rm ${local.installerdir}/openshift/99_openshift-cluster-api_worker-machineset*
cp ${path.module}/templates/99_01-post-deployment.yaml ${local.installerdir}/manifests
cp ${path.module}/templates/99_02-post-deployment.yaml ${local.installerdir}/manifests
cp ${path.module}/templates/99_03-post-deployment.yaml ${local.installerdir}/manifests
cp ${path.module}/templates/99_04-post-deployment.yaml ${local.installerdir}/manifests
EOF
  }
  depends_on = [
    local_file.install_config_yaml
  ]
}

resource "local_file" "cluster_scheduler" {
  content  = data.template_file.cluster_scheduler.rendered
  filename = "${local.installerdir}/manifests/cluster-scheduler-02-config.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

resource "local_file" "post_deployment_05" {
  content  = data.template_file.post_deployment_05.rendered
  filename = "${local.installerdir}/manifests/99_05-post-deployment.yaml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

resource "local_file" "post_deployment_06" {
  content  = data.template_file.post_deployment_06.rendered
  filename = "${local.installerdir}/manifests/99_06-post-deployment.yaml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

resource "null_resource" "generate_ignition" {
  provisioner "local-exec" {
    command = "${local.installerdir}/openshift-install --dir=${local.installerdir}/ create ignition-configs --log-level debug"
  }
  depends_on = [
    local_file.cluster_scheduler,
    local_file.post_deployment_05,
    local_file.post_deployment_06
  ]
}


data "local_file" "bootstrap_ignition" {
  filename = "${local.installerdir}/bootstrap.ign"
  depends_on = [
    null_resource.generate_ignition
  ]
}

data "local_file" "master_ignition" {
  filename = "${local.installerdir}/master.ign"
  depends_on = [
    null_resource.generate_ignition
  ]
}

data "local_file" "worker_ignition" {
  filename = "${local.installerdir}/worker.ign"
  depends_on = [
    null_resource.generate_ignition
  ]
}

