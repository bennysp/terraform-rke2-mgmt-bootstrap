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
