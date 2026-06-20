# Proxmox Node Driver Validation Matrix (Non-Destructive)

## Scope

This checklist validates whether a Rancher Proxmox node-driver flow is safe enough to adopt in your environment.

It is intentionally non-destructive:
- no changes to existing production clusters
- no replacement of your current Proxmox Terraform VM lifecycle path
- tests are done in isolated dev/sandbox resources only

## Current Baseline

- Management stack sequence is:
  1. `10-proxmox`
  2. `20-rke2-rancher`
  3. `30-bootstrap`
- Baseline path to compare against:
  - Proxmox VMs provisioned by Terraform
  - Rancher/Fleet used for cluster management and bootstrap

## Phase 0: Preconditions

Pass all before running driver tests.

- [ ] Rancher version and `rancher2` provider version are recorded.
- [ ] Test Proxmox node/pool/template are dedicated to sandbox.
- [ ] API token for Proxmox has least privilege for test scope only.
- [ ] Snapshot of current management state is captured:
  - `terragrunt stack run plan --source-update --non-interactive` from `terragrunt-rancher-cluster/environments/dev/management`
- [ ] Existing dev management stack apply is green.

## Phase 1: Driver Install Validation (UI only)

Objective: verify custom node driver can be installed and activated without affecting existing clusters.

- [ ] In Rancher, add custom node driver using the candidate URL/checksum.
- [ ] Driver status becomes Active.
- [ ] Driver options form renders correctly in node template creation.
- [ ] No regression in existing cluster provider access.

Fail fast conditions:
- Driver remains in error state.
- Driver activation affects existing vSphere or other driver-backed clusters.

## Phase 2: Node Template Validation (sandbox)

Objective: ensure template settings map correctly to Proxmox resources.

- [ ] Create a sandbox node template with:
  - dedicated Proxmox node/pool
  - small VM sizing
  - isolated network/VLAN
  - cloud-init enabled
- [ ] Validate template save succeeds.
- [ ] Validate no hidden required fields missing.

Evidence to capture:
- Node template spec screenshot/export.
- Proxmox VM config created by template test.

## Phase 3: Cluster Lifecycle Matrix (sandbox)

Create one short-lived sandbox cluster via driver and validate core lifecycle.

| Test | Expected | Result |
|---|---|---|
| Create 1 control-plane + 1 worker | Cluster reaches Active | TODO |
| Add 1 worker (scale out) | New VM created, node Ready | TODO |
| Remove 1 worker (scale in) | VM cleanup and node removal succeed | TODO |
| Upgrade patch version | Upgrade completes, workloads recover | TODO |
| Delete cluster | All test VMs and objects removed cleanly | TODO |

Mandatory checks per test:
- [ ] Rancher cluster state transitions complete without manual DB/API fixes.
- [ ] Proxmox resources are reconciled (no orphaned VM, disk, NIC).
- [ ] Node labels/taints behavior is consistent after reconciliation.

## Phase 4: Integration With Existing Terragrunt Flow

Objective: prove no conflict with your current stacks.

- [ ] Run management plan again after sandbox tests:
  - `terragrunt stack run plan --source-update --non-interactive` from `terragrunt-rancher-cluster/environments/dev/management`
- [ ] Verify no unexpected drift in:
  - `10-proxmox`
  - `20-rke2-rancher`
  - `30-bootstrap`
- [ ] Confirm Fleet bundles continue to reconcile (`monitoring`, `metallb`, `vault`, `cert-manager`).

## Phase 5: Operational Readiness Gates

All must pass for adoption.

- [ ] Last push and issue response cadence are acceptable for the selected driver.
- [ ] At least one successful create/scale/delete cycle repeated 2 times.
- [ ] Clear rollback documented (disable custom driver, revert to Terraform-provisioned node lifecycle).
- [ ] Team runbook updated with install, upgrade, and break-glass steps.

## Go/No-Go Decision

Use this rubric:

- Go:
  - 100% pass in Phase 1-4
  - no orphan resources in Proxmox
  - no regression in current Terragrunt-managed management stack
- Conditional Go:
  - minor defects with documented workarounds and low operational risk
- No-Go:
  - lifecycle failures (scale-in/delete/orphan cleanup), or drift/regressions in current stack

## Recommended Execution Order

1. Keep current baseline architecture unchanged.
2. Run sandbox driver validation end-to-end.
3. Decide whether driver path is an optional enhancement, not a replacement.

## Notes

If driver validation fails, stay on current architecture:
- Proxmox lifecycle in Terraform
- Rancher + Fleet for management/bootstrap
