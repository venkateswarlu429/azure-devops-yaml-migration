# Service Connections

Service connections live in the Azure DevOps UI (Project Settings →
Service connections), not in this repo. YAML references them by name
only. This project needs at most one, and only for a real deploy
target — the placeholder deploy step in `templates/deploy.yml` uses
none.

## Azure Resource Manager connection (for deploys)

- **Type:** Azure Resource Manager, using workload identity
  federation (preferred) instead of a stored secret. Federation avoids
  a long-lived credential sitting in the connection.
- **Scope (least privilege):** grant the connection's identity access
  to exactly one resource group — the one holding the deploy target
  — not the whole subscription. Replace `<your-resource-group>` with
  the real group name in the UI; it does not appear in this repo.
- **Use in YAML:** a deploy task references the connection by name,
  for example `azureSubscription: <your-service-connection>`.

## Environment approvals (the classic approver replacement)

Classic release stages had named pre-deployment approvers. In YAML,
approval lives on the **environment**, not in the pipeline file:

1. Create the environment named in `deployEnvironment`.
2. On the environment, add **Approvals and checks** → Approvers →
   the person or group who must approve production deploys.
3. Optionally add a **Branch control** check so only `main` can deploy
   (the pipeline's deploy condition already enforces this; the check
   is defense in depth).

No approval configuration appears in this repo, because approvals are
an org-side control. If you skip this step, the deploy stage runs
without human approval — do not enable it until the checks exist.
