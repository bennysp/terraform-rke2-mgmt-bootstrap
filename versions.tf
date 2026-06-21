terraform {
  required_version = ">= 1.6.0"

  required_providers {
    vault = {
      source  = "nexus.ta.domain.thedaily.tv/hashicorp/vault"
      version = "~> 3.10"
    }
    rancher2 = {
      source  = "nexus.ta.domain.thedaily.tv/rancher/rancher2"
      version = "~> 8.0"
    }
    kubernetes = {
      source  = "nexus.ta.domain.thedaily.tv/hashicorp/kubernetes"
      version = "~> 2.29"
    }
    kubectl = {
      source  = "nexus.ta.domain.thedaily.tv/gavinbunney/kubectl"
      version = "~> 1.14"
    }
    restapi = {
      source  = "nexus.ta.domain.thedaily.tv/mastercard/restapi"
      version = "~> 3.0"
    }
  }
}
