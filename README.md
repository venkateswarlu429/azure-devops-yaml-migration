# Azure DevOps YAML Migration

A classic-to-YAML pipeline migration for a small .NET library: a
multi-stage `azure-pipelines.yml` (build → test → publish → deploy)
built from reusable YAML templates, with parameters, conditions, and
variables, plus a NuGet package versioning flow into Azure Artifacts.

## The migration story

Many teams still run classic (UI-built) build and release pipelines.
They work, but they are hard to review, hard to roll back, and they
live outside version control. This project shows the migration path:

1. **Read the classic pipeline** and write down what it does: its
   tasks, its variables, its triggers, its approvals. See
   [`MIGRATION.md`](MIGRATION.md) for the concept-by-concept mapping.
2. **Replace it with YAML in the same repo** (`azure-pipelines.yml`),
   split into reusable templates under `templates/`.
3. **Keep the classic pipeline disabled, not deleted**, until the YAML
   pipeline has run green on the same branches. Rollback is re-enabling
   the classic pipeline.
4. **Move secrets out of the pipeline definition** into variable groups
   and service connections (see `docs/`), with least-privilege access.

No classic-pipeline export file is included here: classic pipelines are
defined in the Azure DevOps UI, not in the repo, so the classic side is
described in prose and tables in `MIGRATION.md` and the YAML side is
the code in this repo.

## Layout

```
azure-pipelines.yml          # multi-stage pipeline: build → test → publish → deploy
templates/
  build.yml                  # restore + build (parameterized)
  test.yml                   # test with results publishing (parameterized)
  publish.yml                # version from git tag, pack, push to Azure Artifacts
  deploy.yml                 # deployment job to an environment (gated by branch)
src/SampleMath/
  SampleMath.csproj          # minimal .NET class library (the packaged artifact)
  Calculator.cs              # small, testable sample code
test/SampleMath.Tests/
  SampleMath.Tests.csproj    # test project referencing SampleMath
  CalculatorTests.cs         # unit tests for Calculator
scripts/
  version-from-tag.sh        # semver from a git tag ref (used by publish.yml)
docs/
  variable-groups.md         # what each variable group holds, secret handling
  service-connections.md     # service connections, least-privilege notes
  artifacts-nuget.md         # NuGet versioning + feed publish/consume flow
MIGRATION.md                 # classic → YAML mapping table and procedure
```

## What each template does

| Template | Purpose | Key parameters |
| --- | --- | --- |
| `templates/build.yml` | Restore and build the solution | `buildConfiguration`, `solution` |
| `templates/test.yml` | Run tests, publish test results | `buildConfiguration`, `testProject` |
| `templates/publish.yml` | Compute the package version from the git tag, pack the library, push it to an Azure Artifacts feed | `feedName`, `packageProject` |
| `templates/deploy.yml` | Deploy to an environment (approval-gated in the org, see below) | `environment`, `deployBranch` |

## Pipeline conditions

- **Publish** runs only on version tags (`refs/tags/v*`): a tag like
  `v1.2.3` produces package version `1.2.3`.
- **Deploy** runs only on the `main` branch, after build, test, and
  publish succeed.
- **Environment approvals** (who must approve a deploy) are configured
  in the Azure DevOps UI on the environment itself, not in YAML — see
  `docs/service-connections.md` and `MIGRATION.md`.

## NuGet versioning flow

1. Tag a release: `git tag v1.2.3 && git push origin v1.2.3`.
2. The pipeline trigger on tags starts the publish stage.
3. `scripts/version-from-tag.sh` strips the leading `v` and validates
   the result as semantic versioning.
4. `dotnet pack` builds `SampleMath` with that version.
5. `dotnet nuget push` publishes it to the Azure Artifacts feed named
   in the `feedName` parameter.
6. Consumers restore it with a `PackageReference` to `SampleMath` at
   the published version. Full steps: `docs/artifacts-nuget.md`.

## Validation (honest)

What was actually checked in this environment:

- Every YAML file parses cleanly (checked with a YAML parser).
- Every template reference in `azure-pipelines.yml` resolves to a file
  that exists in `templates/`.
- `scripts/version-from-tag.sh` was executed locally with sample refs:
  `refs/tags/v1.2.3` → `1.2.3`,
  `refs/tags/v2.0.0-beta.1` → `2.0.0-beta.1`, and a non-tag branch
  → the documented `0.1.0-ci.<build-number>` fallback.
- All organization, project, feed, subscription, and environment names
  in this repo are placeholders (angle-bracket values). No real IDs,
  URLs, tokens, or secrets appear anywhere.

What was NOT run (no live Azure DevOps org was available, and the
.NET SDK is not installed in this environment):

- The pipeline has NOT been executed in a live Azure DevOps org.
- `dotnet restore`, `dotnet build`, `dotnet test`, and `dotnet pack`
  have NOT been run here — the .NET code is authored, not compiled.
- No package has been published to a real Azure Artifacts feed, and
  no feed has been consumed.
- The classic pipeline described in `MIGRATION.md` is a representative
  description, not an export from a real org.

To run this for real, you need an Azure DevOps organization, the
variable groups and service connection from `docs/`, and a feed created
in Artifacts. Nothing else in the repo needs to change.

## License

MIT — © 2026 Venkateswarlu Maddula.
