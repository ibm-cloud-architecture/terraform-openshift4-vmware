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
      cpus: ${var.control_plane_num_cpus}
      memoryMB: ${var.control_plane_memory}
      osDisk:
        diskSizeGB: ${var.control_plane_disk_size}
  replicas: ${var.control_plane_count}
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


data "template_file" "mtu_script" {
  template = templatefile("${path.module}/templates/30-mtu", {
    mtu       = var.worker_mtu
    interface = var.default_interface
  })
}

data "template_file" "mtu_machineconfig" {
  template = <<EOF
kind: MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
metadata:
  name: 99-worker-mtu
  creationTimestamp: 
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  osImageURL: ''
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - filesystem: root
        path: "/etc/NetworkManager/dispatcher.d/30-mtu"
        contents:
          source: data:text/plain;charset=utf-8;base64,${base64encode(data.template_file.mtu_script.rendered)}
          verification: {}
        mode: 0755
    systemd:
      units:
        - contents: |
            [Unit]
            Requires=systemd-udevd.target
            After=systemd-udevd.target
            Before=NetworkManager.service
            DefaultDependencies=no
            [Service]
            Type=oneshot
            ExecStart=/usr/sbin/restorecon /etc/NetworkManager/dispatcher.d/30-mtu
            [Install]
            WantedBy=multi-user.target
          name: one-shot-mtu.service
          enabled: true
EOF
}


data "template_file" "chrony_config" {
  template = templatefile("${path.module}/templates/chrony.conf", {
    server = var.ntp_server
  })
}

data "template_file" "chrony_config_masters" {
  template = <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-masters-chrony-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
        - contents:
            source: data:text/plain;charset=utf-8;base64,${base64encode(data.template_file.chrony_config.rendered)}
          mode: 420
          overwrite: true
          path: /etc/chrony.conf
  osImageURL: ""
EOF
}

data "template_file" "chrony_config_workers" {
  template = <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-workers-chrony-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
        - contents:
            source: data:text/plain;charset=utf-8;base64,${base64encode(data.template_file.chrony_config.rendered)}
          mode: 420
          overwrite: true
          path: /etc/chrony.conf
  osImageURL: ""
EOF
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

resource "local_file" "mtu_configuration" {
  count    = var.worker_mtu == 1500 ? 0 : 1
  content  = data.template_file.mtu_machineconfig.rendered
  filename = "${local.installerdir}/manifests/99_worker_mtu-machineconfig.yaml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

resource "local_file" "ntp_masters" {
  count    = var.ntp_server == "" ? 0 : 1
  content  = data.template_file.mtu_machineconfig.rendered
  filename = "${local.installerdir}/manifests/99_master_ntp-machineconfig.yaml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

resource "local_file" "ntp_workers" {
  count    = var.ntp_server == "" ? 0 : 1
  content  = data.template_file.mtu_machineconfig.rendered
  filename = "${local.installerdir}/manifests/99_worker_ntp-machineconfig.yaml"
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

