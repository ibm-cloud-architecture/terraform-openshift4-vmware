output "module_completed" {
  value = join(",", concat(null_resource.generateisos.*.id))
}
