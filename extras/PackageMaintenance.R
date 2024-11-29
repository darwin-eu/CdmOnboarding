# Prerequisites
# Have two remotes:
# 1. To the private repository darwin-dev (darwin-eu-dev/DashboardExport)
# 2. To the public repository darwin-public (darwin-eu/DashboardExport)

# Development should happen on the develop branch of darwin-dev

# Upon release:
# 1. From develop, create a release-candidate branch from develop, e.g. release-v2.0
# 1.1 Add release notes to NEWS.md
# 2. Bump version in DESCRIPTION
# 2.1 Run Document and Check. Check should finish without notes, warnings or errors.
# 2.2 Commit and push changes to release-candidate branch
# 2.3 Add example report, `CdmOnboarding_Syntha20k-vx.x.x.docx` for latest release.
# 3. Create Github PR to main
# 4. Review and merge PR
# 5. Create Github release on darwin-eu-dev, main branch, creating a tag as well.
# 6. Git checkout main and pull
# 7. Push to darwin-public: `git push --tags darwin-public main`
# 8. Git checkout develop and merge main, bump dev version in DESCRIPTION (add .900)
# 9. Create Github release on darwin-eu, reusing tag.