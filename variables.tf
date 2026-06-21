variable "vault_kubeconfig_secret_mount" {
  description = "Vault KV v2 mount containing kubeconfig secret."
  type        = string
  default     = "secret"
}

variable "vault_kubeconfig_secret_name" {
  description = "Vault KV v2 secret name containing kubeconfig payload."
  type        = string
  default     = "kubernetes/upstream/dev/k8sconfig"
}

variable "vault_kubeconfig_secret_key" {
  description = "Field key for kubeconfig payload in Vault secret."
  type        = string
  default     = "data"
}

variable "vault_kubeconfig_is_base64" {
  description = "Whether kubeconfig payload in Vault is base64 encoded."
  type        = bool
  default     = true
}

variable "vault_github_secret_path" {
  description = "Vault KV v2 path for Git credentials, e.g. secret/github/creds."
  type        = string
  default     = "secret/forgejo/rancher"
}

variable "vault_github_username_key" {
  description = "Username key in Git credentials secret."
  type        = string
  default     = "username"
}

variable "vault_github_password_key" {
  description = "Password/token key in Git credentials secret."
  type        = string
  default     = "token"
}

variable "vault_rancher_api_secret_path" {
  description = "Vault path containing Rancher API endpoint and token used to manage node drivers and machine configs."
  type        = string
  default     = "secret/rancher/clusters/local"
}

variable "vault_rancher_api_url_key" {
  description = "Vault key that stores Rancher API URL."
  type        = string
  default     = "rancher-api-url"
}

variable "vault_rancher_api_token_key" {
  description = "Vault key that stores Rancher API token."
  type        = string
  default     = "rancher-api-secret"
}

variable "vault_proxmox_api_secret_path" {
  description = "Vault path containing Proxmox API credential values used to create Rancher cloud credential."
  type        = string
  default     = "secret/proxmox/api"
}

variable "vault_proxmox_api_url_key" {
  description = "Vault key containing Proxmox API URL (for example https://proxmox.example:8006)."
  type        = string
  default     = "url"
}

variable "vault_proxmox_api_token_key" {
  description = "Vault key containing combined Proxmox API token value tokenId=tokenSecret."
  type        = string
  default     = "token"
}

variable "proxmox_cloud_credential_name" {
  description = "Rancher cloud credential object name for Proxmox."
  type        = string
  default     = "proxmox-cred"
}

variable "proxmox_cloud_credential_description" {
  description = "Description shown in Rancher for Proxmox cloud credential."
  type        = string
  default     = "Proxmox VE API credential"
}

variable "proxmox_cloud_credential_insecure_tls" {
  description = "Whether to skip TLS verification for Proxmox API in Rancher cloud credential."
  type        = bool
  default     = true
}

variable "proxmox_node_driver_name" {
  description = "Rancher node driver display name."
  type        = string
  default     = "pve"
}

variable "proxmox_node_driver_url" {
  description = "Download URL for the Proxmox node driver binary."
  type        = string
  default     = "https://github.com/Stellatarum/docker-machine-driver-pve/releases/download/v1.2.0-rc2/docker-machine-driver-pve"
}

variable "proxmox_node_driver_whitelist_domains" {
  description = "Domains to whitelist for driver and UI URLs."
  type        = list(string)
  default = [
    "github.com",
    "githubusercontent.com",
    "objects.githubusercontent.com",
    "raw.githubusercontent.com",
    "*.domain.thedaily.tv",
    "domain.thedaily.tv",
    "proxmox.domain.thedaily.tv",
    "virthost01.domain.thedaily.tv",
    "proxmox.domain.thedaily.tv:8006",
  ]
}

variable "proxmox_extension_repo_name" {
  description = "Rancher Apps repository name for the upstream Proxmox node driver chart."
  type        = string
  default     = "pve-node-driver"
}

variable "proxmox_extension_repo_url" {
  description = "Rancher Apps repository URL for the Proxmox node driver extension chart index."
  type        = string
  default     = "https://stellatarum.github.io/docker-machine-driver-pve"
}

variable "proxmox_extension_chart_name" {
  description = "Chart name to install from proxmox_extension_repo_url."
  type        = string
  default     = "pve-node-driver"
}

variable "proxmox_extension_namespace" {
  description = "Namespace where the Proxmox extension chart is installed."
  type        = string
  default     = "cattle-ui-plugin-system"
}

variable "proxmox_extension_install_timeout_seconds" {
  description = "Timeout for extension chart install/upgrade."
  type        = number
  default     = 900
}

variable "proxmox_node_driver_ready_timeout_seconds" {
  description = "Maximum seconds to wait for Proxmox node driver to be installed and CRDs to be registered."
  type        = number
  default     = 900
}

variable "proxmox_node_driver_ready_poll_interval_seconds" {
  description = "Polling interval in seconds while waiting for Proxmox node driver readiness."
  type        = number
  default     = 10
}

variable "proxmox_machine_config_crd_name" {
  description = "Machine config CRD name that must exist before creating machine config objects."
  type        = string
  default     = "pveconfigs.rke-machine-config.cattle.io"
}

variable "proxmox_machine_configs" {
  description = "Map of Proxmox machine config objects keyed by metadata.name. Values are rendered as CR manifests."
  type = map(object({
    kind        = optional(string, "PveConfig")
    api_version = optional(string, "rke-machine-config.cattle.io/v1")
    namespace   = optional(string, "fleet-default")
    spec        = map(any)
  }))
  default = {}
}

variable "fleet_namespace" {
  description = "Namespace where Fleet GitRepo resources and git secret are created."
  type        = string
  default     = "fleet-default"
}

variable "fleet_git_secret_name" {
  description = "Secret name used by Fleet GitRepo clientSecretName."
  type        = string
  default     = "github-creds"
}

variable "fleet_repo_url" {
  description = "Git repository URL for Fleet bundles."
  type        = string
  default     = "https://forgejo.ta.domain.thedaily.tv/bennysp/rancher-contdelivery.git"
}

variable "fleet_branch" {
  description = "Git branch for Fleet bundles."
  type        = string
  default     = "main"
}

variable "fleet_insecure_skip_tls_verify" {
  description = "Set true for self-signed/private Git TLS endpoints."
  type        = bool
  default     = true
}

variable "bundle_targets" {
  description = "Fleet targets applied to each GitRepo bundle."
  type = list(object({
    cluster_selector = map(string)
  }))
  default = [
    {
      cluster_selector = {}
    }
  ]
}

variable "bootstrap_bundles" {
  description = "Map of Fleet bundle definitions keyed by GitRepo name."
  type = map(object({
    path        = string
    description = string
    enabled     = optional(bool, true)
  }))
  default = {
    monitoring = {
      path        = "/fleet/rancher-monitoring"
      description = "Monitoring for Rancher clusters"
      enabled     = true
    }
    metallb = {
      path        = "/fleet/metallb"
      description = "MetalLB for Rancher clusters"
      enabled     = true
    }
    vault = {
      path        = "/fleet/vault-operator"
      description = "Vault Operator for Rancher clusters"
      enabled     = true
    }
    cert-manager = {
      path        = "/fleet/certmanager"
      description = "Cert Manager for Rancher clusters"
      enabled     = true
    }
    ceph = {
      path        = "/fleet/ceph"
      description = "Ceph storage integration for Rancher clusters"
      enabled     = false
    }
    nginx-ingress = {
      path        = "/fleet/nginx-ingress"
      description = "NGINX Ingress for Rancher clusters"
      enabled     = false
    }
    cluster-autoscaler = {
      path        = "/fleet/cluster-autoscaler"
      description = "Cluster Autoscaler for Rancher clusters"
      enabled     = false
    }
  }
}
