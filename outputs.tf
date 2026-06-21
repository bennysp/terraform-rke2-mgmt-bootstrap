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
  value       = var.proxmox_node_driver_enabled ? var.proxmox_node_driver_name : null
}

output "proxmox_machine_config_names" {
  description = "Names of Proxmox machine config objects created by bootstrap."
  value       = sort(keys(kubectl_manifest.proxmox_machine_config))
}
