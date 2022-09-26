output "module_completed" {
  value = null_resource.generate_ignition.id
}

output "bootstrap_ignition" {
  value = data.local_file.bootstrap_ignition.content
}

output "master_ignition" {
  value = data.local_file.master_ignition.content
}

output "worker_ignition" {
  value = data.local_file.worker_ignition.content
}
output "kubeadmin_password_file" {
  value = data.local_file.kubeadmin_password_file.content
}

output "kubeconfig_file" {
  value = data.local_file.kubeconfig_file.content
}
