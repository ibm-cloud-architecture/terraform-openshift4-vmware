output "bootstrap_ignition" {
  value = module.ignition.bootstrap_ignition
}

output "master_ignition" {
  value = module.ignition.master_ignition
}

output "worker_ignition" {
  value = module.ignition.worker_ignition
}

output "kubeadmin_password_file" {
  value = module.ignition.kubeadmin_password_file
}

output "kubeconfig_file" {
  value = module.ignition.kubeconfig_file
}
