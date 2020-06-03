resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependson)
  }
}

resource "null_resource" "approve_certs" {
  depends_on = [
    null_resource.dependency
  ]
  triggers = {
    master_hostnames  = join(",", var.master_hostnames)
    worker_hostnames  = join(",", var.worker_hostnames)
    storage_hostnames = join(",", var.storage_hostnames)
  }
  connection {
    host        = var.helper_public_ip
    user        = var.helper["username"]
    password    = var.helper["password"]
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=~/installer/auth/kubeconfig",
      "oc get csr -o name | xargs oc adm certificate approve"
    ]
  }
}


locals {
  install_api_certificate = var.api_certificate != null && var.api_certificate_key != null && var.cluster_id != null && var.base_domain != null
  install_apps_certficate = var.custom_ca_bundle != null && var.apps_certificate != null && var.apps_certificate_key != null
}

resource "null_resource" "install_api_certificate" {
  count = local.install_api_certificate ? 1 : 0
  depends_on = [
    null_resource.approve_certs
  ]

  connection {
    host        = var.helper_public_ip
    user        = var.helper["username"]
    password    = var.helper["password"]
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    content     = file(var.api_certificate)
    destination = "/tmp/api.crt"
  }

  provisioner "file" {
    content     = file(var.api_certificate_key)
    destination = "/tmp/api.key"
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=~/installer/auth/kubeconfig",
      "oc create secret tls api-certificate --cert=/tmp/api.crt --key=/tmp/api.key -n openshift-config",
      "oc patch apiserver cluster --type=merge -p '{\"spec\":{\"servingCerts\": {\"namedCertificates\": [{\"names\": [\"api.${var.cluster_id}.${var.base_domain}\"], \"servingCertificate\": {\"name\": \"api-certificate\"}}]}}}'",
    ]
  }
}


resource "null_resource" "install_apps_certificate" {
  count = local.install_apps_certficate ? 1 : 0
  depends_on = [
    null_resource.approve_certs
  ]

  connection {
    host        = var.helper_public_ip
    user        = var.helper["username"]
    password    = var.helper["password"]
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    content     = file(var.apps_certificate)
    destination = "/tmp/apps.crt"
  }

  provisioner "file" {
    content     = file(var.apps_certificate_key)
    destination = "/tmp/apps.key"
  }

  provisioner "file" {
    content     = file(var.custom_ca_bundle)
    destination = "/tmp/ca.crt"
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=~/installer/auth/kubeconfig",
      "oc create configmap custom-ca --from-file=ca-bundle.crt=/tmp/ca.crt -n openshift-config",
      "oc patch proxy/cluster --type=merge --patch='{\"spec\":{\"trustedCA\":{\"name\":\"custom-ca\"}}}'",
      "oc create secret tls apps-certificate --cert=/tmp/apps.crt --key=/tmp/apps.key -n openshift-ingress",
      "oc patch ingresscontroller.operator default --type=merge -p '{\"spec\":{\"defaultCertificate\": {\"name\": \"apps-certificate\"}}}' -n openshift-ingress-operator"
    ]
  }
}
