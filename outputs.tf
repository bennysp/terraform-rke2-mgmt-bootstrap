output "applied_bundles" {
  description = "List of Fleet GitRepo bundle names applied by bootstrap."
  value       = sort(keys(local.enabled_bundles))
}

output "fleet_namespace" {
  description = "Namespace where Fleet bootstrap resources were created."
  value       = var.fleet_namespace
}
