resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependson)
  }
}

resource "null_resource" "waitfor" {
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
      "/usr/local/bin/openshift-install --dir=installer wait-for bootstrap-complete",
      "/usr/local/bin/openshift-install --dir=installer wait-for install-complete",
    ]
  }
}


# resource "null_resource" "taint_storage_nodes" {
#   count = var.storage["count"]
#   depends_on = [
#     null_resource.waitfor
#   ]

#   connection {
#     host        = var.helper_public_ip
#     user        = var.helper["username"]
#     password    = var.helper["password"]
#     private_key = var.ssh_private_key
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export KUBECONFIG=~/installer/auth/kubeconfig",
#       "oc adm taint node ${var.storage_hostnames[count.index]}.${var.cluster_id}.${var.base_domain} node.ocs.openshift.io/storage=true:NoSchedule",
#       "oc label node ${var.storage_hostnames[count.index]}.${var.cluster_id}.${var.base_domain} cluster.ocs.openshift.io/openshift-storage=''"
#     ]
#   }
# }

# resource "null_resource" "install_ocs" {
#   count = (var.storage["count"] == "0") ? 0 : 1
#   depends_on = [
#     null_resource.taint_storage_nodes
#   ]

#   connection {
#     host        = var.helper_public_ip
#     user        = var.helper["username"]
#     password    = var.helper["password"]
#     private_key = var.ssh_private_key
#   }

#   provisioner "file" {
#     source      = "${path.module}/scripts"
#     destination = "/tmp/deployment_scripts"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo chmod u+x /tmp/deployment_scripts/*.sh",
#       "/tmp/deployment_scripts/deploy.sh"
#     ]
#   }
# }
