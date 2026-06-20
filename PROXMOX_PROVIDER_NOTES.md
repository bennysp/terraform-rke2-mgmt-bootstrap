# Rancher Proxmox Provider Notes

## Quick finding

A direct Proxmox machine config for `rancher2_cluster_v2` is not visible in the local Rancher Terraform provider docs/changelog available in this workspace.

## Recommended modern pattern

1. Keep node lifecycle in Proxmox Terraform:
- Use `terraform-proxmox` to create VM infrastructure.

2. Use Rancher for cluster/bootstrap and GitOps:
- Use Rancher management and Fleet bootstrap (`terraform-rke2-mgmt` + `terraform-rke2-mgmt-bootstrap`).

3. For downstream clusters:
- Prefer provisioning nodes on Proxmox first, then attach/register through Rancher workflows rather than relying on a direct vSphere-style machine config.

## Why this is safer than legacy vSphere parity

- Your stack already standardizes infrastructure on Proxmox Terraform.
- It avoids coupling cluster creation to cloud-driver assumptions that were specific to vSphere.
- It keeps bootstrap and app delivery in Fleet where it belongs.

## Future options to evaluate

- Evaluate Rancher node driver capabilities (`rancher2_node_driver` / `rancher2_node_template`) only if you specifically need node-driver-based dynamic scaling from Rancher.
- If no stable Proxmox node-driver path exists for your Rancher version, continue with Terraform-provisioned Proxmox nodes plus Rancher registration/bootstrap.

## Validation matrix

- See `PROXMOX_DRIVER_VALIDATION_MATRIX.md` for a non-destructive test plan and go/no-go criteria before adopting any Proxmox node-driver workflow.
