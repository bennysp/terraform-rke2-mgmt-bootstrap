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
- Deployment mode is controlled by `proxmox_node_driver_deploy_mode`:
  - `kubectl` (default): apply Rancher `NodeDriver` CRD via Kubernetes API (native-first path)
  - `rancher2`: use Rancher API provider (fallback)
- Rancher API URL/token are read from Vault path `vault_rancher_api_secret_path`.
- Optional Proxmox machine-config CR creation is supported via `kubectl_manifest`:
	- set `proxmox_machine_configs_enabled = true`
	- define `proxmox_machine_configs` map keyed by config object name (for example cp/worker)
	- `proxmox_machine_config_wait_duration` controls the provider-based wait after node driver creation before machine-config CRs are applied (default `45s`)
- Downstream provisioning can then reference these machine configs by `kind`/`name` with no manual Rancher UI object creation.

## Vault Secret Expectations

- `vault_github_secret_path` should resolve with Git auth keys.
	- Primary keys: `vault_github_username_key` and `vault_github_password_key` (defaults: `user`, `token`).
	- Fallback keys are also accepted: username (`username`, `user`, `login`) and password/token (`password`, `token`, `pat`, `access_token`).
	- Bootstrap now fails early if username or password/token resolves empty.
- `vault_rancher_api_secret_path` should resolve with keys matching `vault_rancher_api_url_key` and `vault_rancher_api_token_key` (defaults: `rancher-api-url`, `rancher-api-secret`).

Rancher Management bootstrap module