variable "vault_kubeconfig_secret_mount" {
  description = "Vault KV v2 mount containing kubeconfig secret."
  type        = string
  default     = "secret"
}

variable "depends_on_rancher_url" {
  description = "Terragrunt dependency passthrough used only to enforce ordering."
  type        = string
  default     = ""
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
  default     = "secret/github/creds"
}

variable "vault_github_username_key" {
  description = "Username key in Git credentials secret."
  type        = string
  default     = "user"
}

variable "vault_github_password_key" {
  description = "Password/token key in Git credentials secret."
  type        = string
  default     = "token"
}

variable "vault_rancher_secret_path" {
  description = "Legacy variable kept for compatibility. Not used for Rancher API in this module."
  type        = string
  default     = "secret/rancher/clusters/local"
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

variable "proxmox_node_driver_enabled" {
  description = "If true, deploys/updates a Proxmox custom node driver in Rancher management."
  type        = bool
  default     = false
}

variable "proxmox_node_driver_name" {
  description = "Rancher node driver display name."
  type        = string
  default     = "proxmoxve"
}

variable "proxmox_node_driver_url" {
  description = "Download URL for the Proxmox node driver binary tarball."
  type        = string
  default     = "https://github.com/Stellatarum/docker-machine-driver-pve/releases/download/v1.2.0-rc2/docker-machine-driver-pve_v1.2.0-rc2_linux_amd64.tar.gz"
}

variable "proxmox_node_driver_checksum" {
  description = "Optional checksum for downloaded node driver binary."
  type        = string
  default     = ""
}

variable "proxmox_node_driver_description" {
  description = "Description shown in Rancher for the custom node driver."
  type        = string
  default     = "Proxmox VE node driver"
}

variable "proxmox_node_driver_ui_url" {
  description = "Optional UI extension URL for the custom node driver."
  type        = string
  default     = ""
}

variable "proxmox_node_driver_whitelist_domains" {
  description = "Domains to whitelist for driver and UI URLs."
  type        = list(string)
  default = [
    "github.com",
    "githubusercontent.com",
    "objects.githubusercontent.com",
    "raw.githubusercontent.com",
  ]
}

variable "proxmox_machine_configs_enabled" {
  description = "If true, creates Proxmox machine config CRs in Rancher for downstream cluster pools."
  type        = bool
  default     = false
}

variable "proxmox_machine_configs" {
  description = "Map of Proxmox machine config objects keyed by metadata.name. Values are rendered as CR manifests."
  type = map(object({
    kind        = optional(string, "ProxmoxveConfig")
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
