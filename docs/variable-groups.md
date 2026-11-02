# Variable Groups

Variable groups live in the Azure DevOps UI (Pipelines → Library),
not in this repo. YAML references them by name only. Create these
two groups before running the pipeline.

## `app-shared` (non-secret values)

| Variable | Example value | Notes |
| --- | --- | --- |
| `buildConfiguration` | `Release` | Overridden by the YAML default if absent |
| `feedName` | `<your-feed>` | Azure Artifacts feed name (see `docs/artifacts-nuget.md`) |
| `deployEnvironment` | `<your-environment>` | Environment the deploy stage targets |

## `app-prod-secrets` (secret values — names only, never values)

| Variable | How it is stored |
| --- | --- |
| Any API key or token a deploy step needs | Mark the variable secret in the group, or link the group to an Azure Key Vault and store the secret there |

Rules that apply to both groups:

- **No secret value ever appears in YAML or in git.** If a value
  would be a secret, it goes in a group (or Key Vault) and only its
  name is referenced.
- **Least privilege:** link a secret group only to the pipelines that
  need it. The build and test stages in this repo do not need
  `app-prod-secrets`; only a real deploy step would.
- **Classic parity:** these groups are the same groups the classic
  pipeline used. Migration does not recreate them — YAML references
  the existing ones by name.
