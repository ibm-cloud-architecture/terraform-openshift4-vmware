output "module_completed" {
  value = join(",", concat(vsphere_virtual_machine.vm.*.id))
}
