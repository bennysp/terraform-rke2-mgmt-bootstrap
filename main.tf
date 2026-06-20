locals {
  github_secret_parts = [for p in split("/", trim(var.vault_github_secret_path, "/")) : p if p != ""]
  github_secret_mount = length(local.github_secret_parts) > 0 ? local.github_secret_parts[0] : ""
  github_secret_name  = length(local.github_secret_parts) > 1 ? join("/", slice(local.github_secret_parts, 1, length(local.github_secret_parts))) : ""
}

data "vault_kv_secret_v2" "kubeconfig" {
  mount = var.vault_kubeconfig_secret_mount
  name  = var.vault_kubeconfig_secret_name
}

data "vault_kv_secret_v2" "github" {
  mount = local.github_secret_mount
  name  = local.github_secret_name
}

locals {
  kubeconfig_raw = try(tostring(data.vault_kv_secret_v2.kubeconfig.data[var.vault_kubeconfig_secret_key]), "")
  kubeconfig_yaml = trimspace(local.kubeconfig_raw) != "" ? (
    var.vault_kubeconfig_is_base64 ? base64decode(local.kubeconfig_raw) : local.kubeconfig_raw
  ) : ""
  kubeconfig_obj = try(yamldecode(local.kubeconfig_yaml), tomap({}))

  kube_current_context_name = try(tostring(local.kubeconfig_obj["current-context"]), "")
  kube_context_entry = try([
    for c in try(local.kubeconfig_obj.contexts, []) : c if try(tostring(c.name), "") == local.kube_current_context_name
  ][0], tomap({}))

  kube_cluster_name = try(tostring(local.kube_context_entry.context.cluster), "")
  kube_user_name    = try(tostring(local.kube_context_entry.context.user), "")

  kube_cluster_entry = try([
    for c in try(local.kubeconfig_obj.clusters, []) : c if try(tostring(c.name), "") == local.kube_cluster_name
  ][0], tomap({}))
  kube_user_entry = try([
    for u in try(local.kubeconfig_obj.users, []) : u if try(tostring(u.name), "") == local.kube_user_name
  ][0], tomap({}))

  kube_host               = try(tostring(local.kube_cluster_entry.cluster.server), "")
  kube_ca_certificate     = try(base64decode(local.kube_cluster_entry.cluster["certificate-authority-data"]), "")
  kube_token              = try(tostring(local.kube_user_entry.user.token), "")
  kube_client_certificate = try(base64decode(local.kube_user_entry.user["client-certificate-data"]), "")
  kube_client_key         = try(base64decode(local.kube_user_entry.user["client-key-data"]), "")

  fleet_git_username = try(tostring(data.vault_kv_secret_v2.github.data[var.vault_github_username_key]), "")
  fleet_git_password = try(tostring(data.vault_kv_secret_v2.github.data[var.vault_github_password_key]), "")

  enabled_bundles = {
    for name, cfg in var.bootstrap_bundles : name => cfg if try(cfg.enabled, true)
  }
}

provider "kubernetes" {
  host                   = local.kube_host
  token                  = local.kube_token != "" ? local.kube_token : null
  cluster_ca_certificate = local.kube_ca_certificate != "" ? local.kube_ca_certificate : null
  client_certificate     = local.kube_client_certificate != "" ? local.kube_client_certificate : null
  client_key             = local.kube_client_key != "" ? local.kube_client_key : null
}

provider "kubectl" {
  host                   = local.kube_host
  token                  = local.kube_token != "" ? local.kube_token : null
  cluster_ca_certificate = local.kube_ca_certificate != "" ? local.kube_ca_certificate : null
  client_certificate     = local.kube_client_certificate != "" ? local.kube_client_certificate : null
  client_key             = local.kube_client_key != "" ? local.kube_client_key : null
  load_config_file       = false
}

resource "kubernetes_secret" "fleet_git_auth" {
  metadata {
    name      = var.fleet_git_secret_name
    namespace = var.fleet_namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = local.fleet_git_username
    password = local.fleet_git_password
  }
}

resource "kubectl_manifest" "fleet_gitrepo" {
  for_each = local.enabled_bundles

  yaml_body = templatefile("${path.module}/gitrepo.tpl.yaml", {
    name                     = each.key
    namespace                = var.fleet_namespace
    branch                   = var.fleet_branch
    repo_url                 = var.fleet_repo_url
    secret                   = kubernetes_secret.fleet_git_auth.metadata[0].name
    path                     = each.value.path
    description              = each.value.description
    insecure_skip_tls_verify = var.fleet_insecure_skip_tls_verify
    targets                  = var.bundle_targets
  })
}
