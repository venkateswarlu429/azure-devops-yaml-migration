# Classic → YAML Migration Guide

This guide maps a classic (UI-built) Azure DevOps build + release
pipeline to the YAML pipeline in this repo. The classic side is
described, not exported: classic pipelines live in the Azure DevOps UI
and have no file in the repo. The YAML side is the code here.

## The classic pipeline being replaced (representative)

A typical classic setup for a small .NET library:

- **Build pipeline (classic):** trigger on `main` (CI) and on pull
  requests (PR validation). Tasks in order: NuGet Tool Installer,
  NuGet Restore, Visual Studio Build (Release), Visual Studio Test,
  Publish Build Artifacts. Variables defined in the UI: some plain
  (build configuration), some secret (a feed API key typed into the UI
  and locked). A build badge on the repo README.
- **Release pipeline (classic):** two stages, `Staging` and
  `Production`. Each stage has a pre-deployment approver (a named
  person or group) and a set of tasks: download the build artifact,
  deploy it. Stage variables override the pipeline variables.
- **Shared pieces:** a variable group holding non-secret values used
  by both pipelines, and a service connection used to reach Azure.

## Mapping table: classic concept → YAML equivalent

| Classic concept | YAML equivalent in this repo | Where |
| --- | --- | --- |
| Build pipeline trigger (CI on `main`, PR validation) | `trigger` and `pr` sections | `azure-pipelines.yml` |
| Build tasks (restore, build, test, publish artifacts) | Jobs built from templates | `templates/build.yml`, `templates/test.yml` |
| Task inputs set in the UI (configuration, solution path) | Template `parameters` | Every template's `parameters:` block |
| Plain variables defined in the UI | `variables:` block in YAML | `azure-pipelines.yml` |
| Secret variables typed into the UI | Variable groups linked in YAML, marked secret or backed by Azure Key Vault | `docs/variable-groups.md` |
| Variable group shared across pipelines | `variables: - group: <name>` | `azure-pipelines.yml`, `docs/variable-groups.md` |
| Release pipeline stages (`Staging`, `Production`) | `deployment` jobs with `environment:` | `templates/deploy.yml` |
| Pre-deployment approvers (named people) | Environment approvals and checks, configured on the environment in the UI | `docs/service-connections.md` |
| Stage variables overriding pipeline variables | Stage-level `variables:` and template parameters | `azure-pipelines.yml`, `templates/deploy.yml` |
| Artifact published by the build | `publish` step / pipeline artifact | `templates/publish.yml` |
| Release triggered by a new build | Stage `dependsOn` + branch/tag conditions | `azure-pipelines.yml` |
| Scheduled trigger (nightly build) | `schedules:` section (add if needed) | `azure-pipelines.yml` (not enabled here) |

## What changes, and what stays the same

**Changes:**

- The pipeline definition moves into the repo, so it is reviewed in
  pull requests and versioned with the code.
- Repeated task sequences become one template with parameters instead
  of copy-pasted tasks in the UI.
- Branch and tag gating becomes explicit `condition:` expressions
  instead of release-pipeline trigger filters.
- Approvals move from "a person named on the stage" to checks on the
  environment, which apply no matter which pipeline deploys to it.

**Stays the same:**

- The tasks themselves (restore, build, test, pack, push, deploy).
- The variable groups and service connections — they are referenced
  from YAML, not redefined in it.
- The approval model: a human still approves production deploys; only
  where the approval is configured changes.

## Migration procedure

1. **Inventory the classic pipeline.** List every task, variable,
   trigger, and approver. Compare against the mapping table above.
2. **Create the variable groups and service connection first** (see
   `docs/`). YAML can reference them before any pipeline runs.
3. **Add the YAML files to the repo** and create the pipeline in
   Azure DevOps pointing at `azure-pipelines.yml`. Do not delete the
   classic pipeline yet.
4. **Run the YAML pipeline on a branch** and compare its output with
   the classic pipeline's output: same artifacts, same tests, same
   version.
5. **Enable the YAML pipeline's triggers** (CI on `main`, PR
   validation) and **disable the classic pipeline's triggers**.
6. **Watch one full release cycle** (tag → publish → deploy) through
   the YAML pipeline.
7. **Delete the classic pipeline** only after that cycle is green.
   Until then, rollback is re-enabling the classic triggers.

## Common pitfalls

- **Secrets in YAML.** Never paste a secret into a YAML file. If a
  classic variable was secret, it belongs in a variable group or
  Azure Key Vault, referenced by name only.
- **Approvals forgotten.** YAML has no "pre-deployment approver" field.
  If you skip environment approvals, deploys become unapproved. Set
  them on the environment before enabling the deploy stage.
- **Tag triggers.** A tag push triggers the pipeline only if the YAML
  trigger includes tags (see `azure-pipelines.yml`). A missing tag
  trigger is the most common reason a publish stage never runs.
- **Version drift.** The package version must come from exactly one
  place — here, the git tag. Do not also set a version in the
  `.csproj` by hand, or the two will disagree.
