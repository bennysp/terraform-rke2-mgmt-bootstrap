# terraform-rke2-mgmt-bootstrap

Terraform module for Rancher management bootstrap via Fleet GitRepo resources.

## What It Does

- Reads kubeconfig from Vault and configures Kubernetes providers.
- Reads Git credentials from Vault.
- Creates Fleet git auth secret in `fleet-default` (configurable).
- Creates Fleet `GitRepo` resources for enabled bundle paths from `rancher-contdelivery`.

## Notes

- Longhorn is not included in default bundle set.
- Default enabled bundles are: `monitoring`, `metallb`, `vault`, `cert-manager`.
- `nginx-ingress` and `cluster-autoscaler` are present but disabled by default.
- `ceph` is present as a disabled placeholder for future storageclass integration.
- Bundle set is configurable through `bootstrap_bundles`.
- This module is intended to run after Rancher management deployment is complete.

Rancher Management bootstrap module