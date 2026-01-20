# Updating Packages

Complete workflow for releasing new versions of themes and plugins.

## Quick Reference

```bash
# 1. Make changes, commit
git add .
git commit -m "feat: add new header component"

# 2. Tag new version
git tag -a v1.1.0 -m "Release 1.1.0: New header component"
git push origin main --tags

# 3. Satis rebuilds automatically (webhook)
# Or manually: docker exec satis /satis/bin/satis build

# 4. Update on client sites
cd /path/to/client-site
composer update agency/base-theme
```

## Step-by-Step Release Process

### Step 1: Make Changes

**In your theme/plugin repository:**

```bash
cd agency-base-theme

# Create feature branch (optional but recommended)
git checkout -b feature/new-header

# Make changes
vim templates/header.php
vim assets/css/header.scss

# Test locally with a Bedrock site
cd ../client-test-site
composer config repositories.local path ../agency-base-theme
composer require agency/base-theme:@dev
```

### Step 2: Update Documentation

**Update CHANGELOG.md:**
```markdown
# Changelog

## [1.1.0] - 2024-01-15

### Added
- New responsive header component
- Mobile navigation improvements

### Changed
- Updated header styling for better contrast

### Fixed
- Header z-index issue on mobile devices
```

**Update README.md** (if public-facing changes).

**Update composer.json version** (optional, git tags take precedence):
```json
{
  "version": "1.1.0"
}
```

### Step 3: Commit Changes

```bash
git add .
git commit -m "feat: add responsive header component

- Implements new mobile-first header design
- Improves accessibility with ARIA labels
- Fixes z-index stacking issues

Closes #42"
```

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Step 4: Create Git Tag

**Semantic Versioning:**
- **MAJOR**: Breaking changes (2.0.0)
- **MINOR**: New features, backward-compatible (1.1.0)
- **PATCH**: Bug fixes, backward-compatible (1.0.1)

**Create annotated tag:**
```bash
git tag -a v1.1.0 -m "Release 1.1.0: New header component"
```

**Or lightweight tag:**
```bash
git tag v1.1.0
```

**⚠️ Recommendation:** Always use annotated tags (`-a`) for releases.

### Step 5: Push to Remote

```bash
# Push commits
git push origin main

# Push tags
git push origin v1.1.0

# Or push all tags
git push origin --tags
```

**⚠️ Important:** Satis only sees tags that are pushed to remote!

### Step 6: Verify Satis Rebuild

**If webhook configured:**
- Satis rebuilds automatically within 30 seconds
- Check webhook delivery logs in GitHub/GitLab

**Manual verification:**
```bash
# Check Satis build logs
docker logs satis

# Verify package appears
curl -s https://packages.youragency.com/packages.json | jq '.packages["agency/base-theme"]'
```

**Expected output:**
```json
{
  "1.0.0": { ... },
  "1.1.0": {
    "name": "agency/base-theme",
    "version": "1.1.0",
    "dist": {
      "type": "zip",
      "url": "https://packages.youragency.com/dist/agency-base-theme-1.1.0.zip"
    }
  }
}
```

### Step 7: Update Client Sites

**On each Bedrock site:**

```bash
cd /var/www/client-a

# Update specific package
composer update agency/base-theme

# Verify new version installed
composer show agency/base-theme
# Version: 1.1.0

# Check what changed
git diff composer.lock
```

**composer.lock changes:**
```diff
-            "version": "1.0.0",
+            "version": "1.1.0",
```

### Step 8: Test and Deploy

```bash
# Test on development environment
wp theme list
wp server --host=0.0.0.0 --port=8080

# Deploy to staging
git add composer.lock
git commit -m "chore: update base-theme to 1.1.0"
git push origin staging

# Deploy to production (after testing)
git push origin production
```

## Release Types

### Patch Release (1.0.1)

**When:** Bug fixes only, no new features

```bash
git commit -m "fix: resolve header alignment issue"
git tag -a v1.0.1 -m "Release 1.0.1: Bugfix release"
git push origin main --tags
```

**Client update:**
```bash
composer update agency/base-theme
# 1.0.0 → 1.0.1 (automatic with ^1.0 constraint)
```

### Minor Release (1.1.0)

**When:** New features, backward-compatible

```bash
git commit -m "feat: add dark mode support"
git tag -a v1.1.0 -m "Release 1.1.0: Dark mode support"
git push origin main --tags
```

**Client update:**
```bash
composer update agency/base-theme
# 1.0.0 → 1.1.0 (automatic with ^1.0 constraint)
```

### Major Release (2.0.0)

**When:** Breaking changes, incompatible API changes

```bash
git commit -m "feat!: redesign header component API

BREAKING CHANGE: Header component now uses new props structure.
Migration guide: docs/migration-2.0.md"

git tag -a v2.0.0 -m "Release 2.0.0: Major redesign

BREAKING CHANGES:
- New header component API
- Removed legacy template hooks
- Updated CSS class names"

git push origin main --tags
```

**⚠️ Breaking Changes:** Require manual client update:

```json
{
  "require": {
    "agency/base-theme": "^1.0"  // Won't auto-update to 2.0
  }
}
```

**Manual update:**
```bash
# Review breaking changes
curl https://raw.githubusercontent.com/agency/base-theme/v2.0.0/docs/migration-2.0.md

# Update constraint
composer require "agency/base-theme:^2.0"

# Test thoroughly before deploying
```

## Pre-Release Versions

### Alpha/Beta/RC Releases

**Format:** `1.1.0-alpha.1`, `1.1.0-beta.1`, `1.1.0-rc.1`

```bash
git tag -a v1.1.0-beta.1 -m "Release 1.1.0-beta.1"
git push origin --tags
```

**Client installation:**
```json
{
  "require": {
    "agency/base-theme": "1.1.0-beta.1"
  },
  "minimum-stability": "beta"
}
```

**Or:**
```bash
composer require "agency/base-theme:1.1.0-beta.1"
```

### Development Versions

**Use branch names:**

```bash
git checkout -b feature/new-design
git push origin feature/new-design
```

**Client installation:**
```json
{
  "require": {
    "agency/base-theme": "dev-feature/new-design"
  }
}
```

**⚠️ Warning:** Dev versions don't follow semantic versioning and can change without notice.

## Hotfix Workflow

**Scenario:** Production bug needs immediate fix

```bash
# Create hotfix branch from latest tag
git checkout v1.0.0
git checkout -b hotfix/critical-bug

# Fix bug
vim templates/header.php
git commit -m "fix: resolve critical XSS vulnerability"

# Tag hotfix
git tag -a v1.0.1 -m "Release 1.0.1: Security hotfix"

# Merge back to main
git checkout main
git merge hotfix/critical-bug

# Push everything
git push origin main
git push origin v1.0.1

# Update all production sites immediately
for site in client-a client-b client-c; do
  cd "/var/www/$site"
  composer update agency/base-theme
  # Deploy immediately
done
```

## Rollback

**Scenario:** New release has critical bug

### Option A: Tag Previous Version as Latest

```bash
# Don't delete bad tag (breaks existing installs)
# Instead, create new patch with fix

git revert <bad-commit>
git commit -m "fix: revert broken feature"
git tag -a v1.1.1 -m "Release 1.1.1: Rollback broken feature"
git push origin main --tags
```

### Option B: Pin Clients to Previous Version

```bash
# On client sites
composer require "agency/base-theme:1.0.0"

# Locks to specific version until manually updated
```

## Multi-Package Releases

**Scenario:** Base theme and utilities plugin both need updates

```bash
# Update base-theme
cd agency-base-theme
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin --tags

# Update utilities
cd ../agency-utilities
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin --tags

# Update client sites
cd ../client-a
composer update "agency/*"
# Updates both packages simultaneously
```

## Automated Release Workflow

### GitHub Actions Example

**.github/workflows/release.yml:**
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT

      - name: Build assets
        run: |
          npm install
          npm run build

      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ steps.version.outputs.VERSION }}
          body_path: CHANGELOG.md

      - name: Trigger Satis Rebuild
        run: |
          curl -X POST "https://packages.youragency.com/webhook?secret=${{ secrets.WEBHOOK_SECRET }}"
```

**Usage:**
```bash
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin v1.1.0
# GitHub Actions automatically creates release and triggers Satis
```

## Notification to Clients

### Option A: Changelog Newsletter

**Monthly email to clients:**
```
Subject: WordPress Package Updates - January 2024

New releases available:

agency/base-theme v1.1.0
- New responsive header
- Improved mobile navigation
- Performance improvements

agency/utilities v1.2.0
- Added SEO helpers
- Bug fixes

Update command:
composer update "agency/*"
```

### Option B: Slack Notification

**Webhook after release:**
```bash
#!/bin/bash
# notify-slack.sh

PACKAGE=$1
VERSION=$2

curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d "{
    \"text\": \"📦 New release: $PACKAGE $VERSION\",
    \"blocks\": [
      {
        \"type\": \"section\",
        \"text\": {
          \"type\": \"mrkdwn\",
          \"text\": \"*$PACKAGE $VERSION* is now available!\"
        }
      }
    ]
  }"
```

## Best Practices

✅ **DO:**
- Use semantic versioning
- Write meaningful git commit messages
- Update CHANGELOG.md
- Test before tagging
- Use annotated tags for releases
- Tag after merging to main

❌ **DON'T:**
- Delete released tags (breaks existing installs)
- Skip versions (go from 1.0 → 1.2, not 1.0 → 2.0 without 1.1)
- Tag untested code
- Force-push tags
- Reuse tag names

## See Also

- [Version Management](version-management.md) - Semantic versioning details
- [Webhook Configuration](webhooks.md) - Automated Satis rebuilds
- [Bedrock Configuration](../setup/bedrock-configuration.md) - Client site updates
