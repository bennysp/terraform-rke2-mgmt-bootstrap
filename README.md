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

## Proxmox Node Driver Deployment

- Optional Rancher node-driver deployment is supported via `rancher2_node_driver`.
- Set `proxmox_node_driver_enabled = true` to deploy/update the Proxmox custom node driver from management bootstrap.
- Rancher API URL/token are read from Vault path `vault_rancher_secret_path`.
- Downstream provisioning can then reference Proxmox machine configs by `kind`/`name` (see downstream module inputs).

Rancher Management bootstrap module