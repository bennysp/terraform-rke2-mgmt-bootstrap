locals {
  rancher_api_url_dependency = trimspace(var.depends_on_rancher_url)
  rancher_api_url_vault = try(
    trimspace(tostring(data.vault_generic_secret.rancher_local.data[var.vault_rancher_api_url_key])),
    ""
  )
  rancher_api_url_value = try(
    local.rancher_api_url_dependency != "" ? local.rancher_api_url_dependency : local.rancher_api_url_vault,
    local.rancher_api_url_vault
  )
  rancher_api_token_value = try(
    tostring(data.vault_generic_secret.rancher_local.data[var.vault_rancher_api_token_key]),
    ""
  )
  proxmox_secret_data = try(data.vault_generic_secret.proxmox_api.data, {})
  proxmox_api_url = trimspace(try(
    tostring(local.proxmox_secret_data[var.vault_proxmox_api_url_key]),
    ""
  ))
  proxmox_api_token_combined = trimspace(try(
    tostring(local.proxmox_secret_data[var.vault_proxmox_api_token_key]),
    ""
  ))
  proxmox_api_token_parts = split("=", local.proxmox_api_token_combined)

  proxmox_api_token_id = trimspace(try(
    tostring(local.proxmox_secret_data[var.vault_proxmox_api_token_id_key]),
    length(local.proxmox_api_token_parts) > 1 ? local.proxmox_api_token_parts[0] : ""
  ))

  proxmox_api_token_secret = trimspace(try(
    tostring(local.proxmox_secret_data[var.vault_proxmox_api_token_secret_key]),
    length(local.proxmox_api_token_parts) > 1 ? join("=", slice(local.proxmox_api_token_parts, 1, length(local.proxmox_api_token_parts))) : ""
  ))
}

data "vault_kv_secret_v2" "kubeconfig" {
  mount = var.vault_kubeconfig_secret_mount
  name  = var.vault_kubeconfig_secret_name
}

data "vault_generic_secret" "github" {
  path = var.vault_github_secret_path
}

data "vault_generic_secret" "rancher_local" {
  path = var.vault_rancher_api_secret_path
}

data "vault_generic_secret" "proxmox_api" {
  path = var.vault_proxmox_api_secret_path
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

  github_secret_data = try(data.vault_generic_secret.github.data, {})

  # Accept common Vault key conventions so Fleet auth keeps working across legacy/new secret shapes.
  fleet_git_username = trimspace(try(
    tostring(local.github_secret_data[var.vault_github_username_key]),
    tostring(local.github_secret_data["username"]),
    tostring(local.github_secret_data["user"]),
    tostring(local.github_secret_data["login"]),
    ""
  ))
  fleet_git_password = trimspace(try(
    tostring(local.github_secret_data[var.vault_github_password_key]),
    tostring(local.github_secret_data["password"]),
    tostring(local.github_secret_data["token"]),
    tostring(local.github_secret_data["pat"]),
    tostring(local.github_secret_data["access_token"]),
    ""
  ))

  enabled_bundles = {
    for name, cfg in var.bootstrap_bundles : name => cfg if try(cfg.enabled, true)
  }

  proxmox_node_driver_mode = lower(trimspace(var.proxmox_node_driver_deploy_mode))
  proxmox_node_driver_spec = merge(
    {
      active      = true
      builtin     = false
      displayName = var.proxmox_node_driver_name
      url         = var.proxmox_node_driver_url
    },
    trimspace(var.proxmox_node_driver_checksum) != "" ? {
      checksum = var.proxmox_node_driver_checksum
    } : {},
    trimspace(var.proxmox_node_driver_description) != "" ? {
      description = var.proxmox_node_driver_description
    } : {},
    trimspace(var.proxmox_node_driver_ui_url) != "" ? {
      uiUrl = var.proxmox_node_driver_ui_url
    } : {},
    length(var.proxmox_node_driver_whitelist_domains) > 0 ? {
      whitelistDomains = var.proxmox_node_driver_whitelist_domains
    } : {}
  )
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

provider "rancher2" {
  api_url   = local.rancher_api_url_value
  token_key = local.rancher_api_token_value
  insecure  = true
  timeout   = "20m"
}

provider "restapi" {
  uri                  = local.rancher_api_url_value
  bearer_token         = local.rancher_api_token_value
  insecure             = true
  write_returns_object = true
  create_returns_object = true
  id_attribute         = "id"

  headers = {
    "Content-Type" = "application/json"
  }
}

resource "rancher2_catalog_v2" "proxmox_extension_repo" {
  count = var.proxmox_node_driver_enabled && local.proxmox_node_driver_mode == "extension" ? 1 : 0

  cluster_id = "local"
  name       = var.proxmox_extension_repo_name
  url        = var.proxmox_extension_repo_url

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

resource "rancher2_app_v2" "proxmox_node_driver_extension" {
  count = var.proxmox_node_driver_enabled && local.proxmox_node_driver_mode == "extension" ? 1 : 0

  cluster_id    = "local"
  name          = var.proxmox_extension_chart_name
  namespace     = var.proxmox_extension_namespace
  repo_name     = var.proxmox_extension_repo_name
  chart_name    = var.proxmox_extension_chart_name
  chart_version = trimspace(var.proxmox_extension_chart_version) != "" ? var.proxmox_extension_chart_version : null
  values = yamlencode(merge(
    {
      nodeDriver = merge(
        {
          url              = var.proxmox_node_driver_url
          whitelistDomains = var.proxmox_node_driver_whitelist_domains
        },
        trimspace(var.proxmox_node_driver_checksum) != "" ? {
          checksum = var.proxmox_node_driver_checksum
        } : {}
      )
    },
    trimspace(var.proxmox_node_driver_ui_url) != "" ? {
      uiPlugin = {
        endpoint = var.proxmox_node_driver_ui_url
      }
    } : {}
  ))

  timeouts {
    create = "${var.proxmox_extension_install_timeout_seconds}s"
    update = "${var.proxmox_extension_install_timeout_seconds}s"
    delete = "20m"
  }

  depends_on = [
    rancher2_catalog_v2.proxmox_extension_repo,
  ]
}

resource "rancher2_node_driver" "proxmox" {
  count = var.proxmox_node_driver_enabled && local.proxmox_node_driver_mode == "rancher2" ? 1 : 0

  active            = true
  builtin           = false
  name              = var.proxmox_node_driver_name
  url               = var.proxmox_node_driver_url
  checksum          = var.proxmox_node_driver_checksum
  description       = var.proxmox_node_driver_description
  ui_url            = var.proxmox_node_driver_ui_url
  whitelist_domains = var.proxmox_node_driver_whitelist_domains
}

resource "kubectl_manifest" "proxmox_node_driver" {
  count = var.proxmox_node_driver_enabled && local.proxmox_node_driver_mode == "kubectl" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "management.cattle.io/v3"
    kind       = "NodeDriver"
    metadata = {
      name = var.proxmox_node_driver_name
    }
    spec = local.proxmox_node_driver_spec
  })
}

resource "terraform_data" "wait_for_proxmox_driver_ready" {
  count = var.proxmox_node_driver_enabled && var.proxmox_machine_configs_enabled ? 1 : 0

  input = {
    node_driver_name = var.proxmox_node_driver_name
    kubeconfig_hash  = sha256(local.kubeconfig_yaml)
    timeout_seconds  = var.proxmox_node_driver_ready_timeout_seconds
    poll_seconds     = var.proxmox_node_driver_ready_poll_interval_seconds
  }

  triggers_replace = [
    var.proxmox_node_driver_name,
    var.proxmox_node_driver_url,
    var.proxmox_node_driver_deploy_mode,
    sha256(local.kubeconfig_yaml),
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      KCFG_FILE=$(mktemp /tmp/proxmox-driver-kubeconfig.XXXXXX.yaml)
      cat > "$KCFG_FILE" <<'KUBECONFIG_EOF'
${local.kubeconfig_yaml}
KUBECONFIG_EOF

      DRIVER_NAME='${var.proxmox_node_driver_name}'
      TIMEOUT_SECONDS='${var.proxmox_node_driver_ready_timeout_seconds}'
      POLL_SECONDS='${var.proxmox_node_driver_ready_poll_interval_seconds}'
      DEADLINE=$((SECONDS + TIMEOUT_SECONDS))

      while (( SECONDS < DEADLINE )); do
        CRD_READY=false
        DRIVER_DOWNLOADED=false
        DRIVER_INSTALLED=false

        if kubectl --kubeconfig "$KCFG_FILE" get crd '${var.proxmox_machine_config_crd_name}' >/dev/null 2>&1; then
          CRD_READY=true
        fi

        DOWNLOADED_STATUS=$(kubectl --kubeconfig "$KCFG_FILE" get nodedrivers.management.cattle.io "$DRIVER_NAME" -o jsonpath='{.status.conditions[?(@.type=="Downloaded")].status}' 2>/dev/null || true)
        INSTALLED_STATUS=$(kubectl --kubeconfig "$KCFG_FILE" get nodedrivers.management.cattle.io "$DRIVER_NAME" -o jsonpath='{.status.conditions[?(@.type=="Installed")].status}' 2>/dev/null || true)

        [[ "$DOWNLOADED_STATUS" == "True" ]] && DRIVER_DOWNLOADED=true
        [[ "$INSTALLED_STATUS" == "True" ]] && DRIVER_INSTALLED=true

        if [[ "$CRD_READY" == "true" && "$DRIVER_DOWNLOADED" == "true" && "$DRIVER_INSTALLED" == "true" ]]; then
          echo "Proxmox NodeDriver is ready and CRD is registered."
          exit 0
        fi

        sleep "$POLL_SECONDS"
      done

      echo "Timed out waiting for Proxmox NodeDriver readiness."
      kubectl --kubeconfig "$KCFG_FILE" get nodedrivers.management.cattle.io "$DRIVER_NAME" -o yaml || true
      exit 1
    EOT
  }

  depends_on = [
    rancher2_app_v2.proxmox_node_driver_extension,
    rancher2_node_driver.proxmox,
    kubectl_manifest.proxmox_node_driver,
  ]
}

resource "kubectl_manifest" "proxmox_machine_config" {
  for_each = var.proxmox_machine_configs_enabled ? var.proxmox_machine_configs : {}

  yaml_body = yamlencode({
    apiVersion = try(each.value.api_version, "rke-machine-config.cattle.io/v1")
    kind       = try(each.value.kind, "PveConfig")
    metadata = {
      name      = each.key
      namespace = try(each.value.namespace, "fleet-default")
    }
    spec = each.value.spec
  })

  depends_on = [
    rancher2_app_v2.proxmox_node_driver_extension,
    rancher2_node_driver.proxmox,
    kubectl_manifest.proxmox_node_driver,
    terraform_data.wait_for_proxmox_driver_ready,
  ]
}

resource "restapi_object" "proxmox_cloud_credential" {
  count = var.proxmox_cloud_credential_enabled ? 1 : 0

  path        = "/v3/cloudcredentials"
  id_attribute = "id"
  data = jsonencode({
    name        = var.proxmox_cloud_credential_name
    description = var.proxmox_cloud_credential_description
    annotations = {
      "provisioning.cattle.io/driver" = var.proxmox_node_driver_name
    }
    pvecredentialConfig = {
      url         = local.proxmox_api_url
      insecureTls = var.proxmox_cloud_credential_insecure_tls
      tokenId     = local.proxmox_api_token_id
      tokenSecret = local.proxmox_api_token_secret
    }
  })

  ignore_server_additions = true
  ignore_changes_to = [
    "links",
    "actions",
    "baseType",
    "created",
    "createdTS",
    "creatorId",
    "labels",
    "type",
    "uuid",
  ]

  depends_on = [
    rancher2_app_v2.proxmox_node_driver_extension,
  ]

  lifecycle {
    precondition {
      condition = local.proxmox_api_url != "" && local.proxmox_api_token_id != "" && local.proxmox_api_token_secret != ""
      error_message = "Proxmox cloud credential values resolved empty from Vault. Check vault_proxmox_api_secret_path and token/url key settings."
    }
    precondition {
      condition = local.rancher_api_url_value != "" && local.rancher_api_token_value != ""
      error_message = "Rancher API URL/token resolved empty from Vault. Check vault_rancher_api_secret_path and key settings."
    }
  }
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

  lifecycle {
    precondition {
      condition     = local.fleet_git_username != "" && local.fleet_git_password != ""
      error_message = "Fleet Git credentials resolved empty from Vault. Check vault_github_secret_path and username/password key names."
    }
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
