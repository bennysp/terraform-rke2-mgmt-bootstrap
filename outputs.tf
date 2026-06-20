output "applied_bundles" {
  description = "List of Fleet GitRepo bundle names applied by bootstrap."
  value       = sort(keys(local.enabled_bundles))
}

output "fleet_namespace" {
  description = "Namespace where Fleet bootstrap resources were created."
  value       = var.fleet_namespace
}

output "proxmox_node_driver_id" {
  description = "Rancher node driver ID when proxmox node driver deployment is enabled."
  value       = var.proxmox_node_driver_enabled ? rancher2_node_driver.proxmox[0].id : null
}
