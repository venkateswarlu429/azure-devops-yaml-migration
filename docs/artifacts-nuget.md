# Azure Artifacts: NuGet Versioning and Feed Flow

This document describes the package flow. It is documentation for an
Azure DevOps organization: no feed here was published to or consumed
from a live feed, because no live org was available when this project
was written (see the README's Validation section).

## Setup (once, in the Azure DevOps UI)

1. Create an Azure Artifacts feed (Artifacts → Create Feed). Its name
   is the `feedName` value used by the pipeline. Use a placeholder
   name such as `<your-feed>` until you create the real one.
2. Give the pipeline's build identity **Contributor** on that feed so
   the push step can publish. Readers get **Reader**; nobody else
   needs write access.

## Publish flow (tag → package)

1. Tag a release and push the tag:
   `git tag v1.2.3 && git push origin v1.2.3`
2. The pipeline's tag trigger starts a run; the Publish stage runs
   because the branch is `refs/tags/v1.2.3`.
3. `scripts/version-from-tag.sh` computes `1.2.3` and the pipeline
   stores it as `packageVersion`.
4. `dotnet pack` builds `src/SampleMath` with that version. The
   `.csproj` deliberately sets no version itself, so the tag is the
   single source of truth.
5. `dotnet nuget push` publishes `SampleMath.1.2.3.nupkg` to the feed.

Pre-release versions work the same way: tag `v2.0.0-beta.1` and the
package version is `2.0.0-beta.1`. Consumers who want only stable
releases filter on the absence of a `-` suffix.

## Consume flow (feed → project)

A consuming project adds the feed as a package source (its feed URL
follows the standard Azure Artifacts pattern for your organization
and project — replace the placeholders with your real names) and
references the package:

```xml
<PackageReference Include="SampleMath" Version="1.2.3" />
```

Then a normal `dotnet restore` resolves it from the feed. No API key
belongs in the consuming repo: authentication uses the pipeline's
feed permissions or a developer's signed-in Artifacts credential.

## Versioning rules

- One source of truth: the git tag. Never hand-edit a version into
  the `.csproj` alongside it.
- Tags must be valid semantic versions after stripping the leading
  `v`; anything else falls back to `0.1.0-ci.<build-number>` and
  will not publish, because the Publish stage only runs on tags.
- Do not re-push the same version: NuGet feeds are immutable per
  version. A bad release gets a new patch version, not a re-upload.
