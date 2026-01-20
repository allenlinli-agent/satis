# Repository Structure

How to structure WordPress themes and plugins for Satis + Bedrock compatibility.

## Requirements

Every theme/plugin repository must have:

1. **Valid `composer.json`** in repository root
2. **Correct package type** (`wordpress-theme`, `wordpress-plugin`, or `wordpress-muplugin`)
3. **Composer installers dependency** (`composer/installers`)
4. **Semantic version tags** in git (e.g., `v1.0.0`, `v1.1.0`)

## Theme Example

**Repository:** `agency/base-theme`

**Directory Structure:**
```
agency-base-theme/
├── composer.json          ← Required
├── style.css              ← WordPress theme header
├── functions.php
├── index.php
├── templates/
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
└── README.md
```

**composer.json:**
```json
{
  "name": "agency/base-theme",
  "description": "Base WordPress theme for all client sites",
  "type": "wordpress-theme",
  "version": "1.0.0",
  "keywords": ["wordpress", "theme", "base"],
  "license": "proprietary",
  "authors": [
    {
      "name": "Your Agency",
      "email": "dev@youragency.com"
    }
  ],
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0"
  },
  "extra": {
    "installer-name": "agency-base-theme"
  }
}
```

**Key Fields:**
- `"type": "wordpress-theme"` - Tells Composer Installers to install to `web/app/themes/`
- `"composer/installers": "^2.0"` - Required for Bedrock path mapping
- `"installer-name"` - Optional: custom directory name (defaults to package name)

**style.css** (WordPress requirement):
```css
/*
Theme Name: Agency Base Theme
Theme URI: https://youragency.com
Description: Base theme for client sites
Author: Your Agency
Version: 1.0.0
*/
```

## Plugin Example

**Repository:** `agency/utilities-plugin`

**Directory Structure:**
```
agency-utilities/
├── composer.json          ← Required
├── agency-utilities.php   ← Main plugin file
├── src/
│   ├── Admin/
│   ├── Frontend/
│   └── Utilities/
├── assets/
└── README.md
```

**composer.json:**
```json
{
  "name": "agency/utilities",
  "description": "Shared utility functions and features",
  "type": "wordpress-plugin",
  "version": "1.0.0",
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0"
  },
  "autoload": {
    "psr-4": {
      "Agency\\Utilities\\": "src/"
    }
  }
}
```

**agency-utilities.php** (WordPress requirement):
```php
<?php
/**
 * Plugin Name: Agency Utilities
 * Plugin URI: https://youragency.com/plugins/utilities
 * Description: Shared utility functions for all client sites
 * Version: 1.0.0
 * Author: Your Agency
 * License: Proprietary
 */

// Autoload via Composer (Bedrock loads this automatically)
require_once __DIR__ . '/vendor/autoload.php';

// Initialize plugin
\Agency\Utilities\Plugin::init();
```

## MU-Plugin Example

**Repository:** `agency/global-config`

**composer.json:**
```json
{
  "name": "agency/global-config",
  "description": "Must-use plugin for global configuration",
  "type": "wordpress-muplugin",
  "version": "1.0.0",
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0"
  }
}
```

**Difference:** `"type": "wordpress-muplugin"` installs to `web/app/mu-plugins/`

## Version Management

### Using Git Tags (Recommended)

Satis automatically detects git tags as package versions:

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release 1.0.0: Initial release"
git push origin v1.0.0

# Create subsequent versions
git tag -a v1.1.0 -m "Release 1.1.0: Add new features"
git push origin v1.1.0

git tag -a v1.1.1 -m "Release 1.1.1: Bugfix"
git push origin v1.1.1
```

**Tag Format:**
- Prefix with `v` (optional but recommended)
- Follow semantic versioning: `MAJOR.MINOR.PATCH`
- Use annotated tags (`-a` flag) for better git history

### Using Branch Names

Branches are available as `dev-<branch-name>`:

```json
{
  "require": {
    "agency/base-theme": "dev-main",
    "agency/experimental-plugin": "dev-feature-xyz"
  }
}
```

**Use Cases:**
- Development environments: `"dev-develop"`
- Feature branches: `"dev-feature-new-header"`
- Staging: `"dev-staging"`

⚠️ **Warning:** Branch-based versions don't follow semantic versioning and can have breaking changes.

### Version Field in composer.json (Optional)

You can specify version directly in `composer.json`:

```json
{
  "name": "agency/base-theme",
  "version": "1.0.0"
}
```

**When to Use:**
- Non-git repositories (rare)
- Override git tag version (not recommended)

**When NOT to Use:**
- Git-based repos (tags are better)
- Automated CI/CD (harder to update)

## Package Dependencies

### Theme with Plugin Dependency

```json
{
  "name": "agency/advanced-theme",
  "type": "wordpress-theme",
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0",
    "agency/utilities": "^1.0",
    "wpackagist-plugin/advanced-custom-fields": "^6.0"
  }
}
```

When you `composer require agency/advanced-theme`, it automatically pulls in:
- `agency/utilities` plugin
- ACF plugin from WPackagist

### Shared Dependencies

**Base theme** (`agency/base-theme/composer.json`):
```json
{
  "require": {
    "composer/installers": "^2.0",
    "wpackagist-plugin/timber-library": "^2.0"
  }
}
```

**Child theme** (`agency/client-a-theme/composer.json`):
```json
{
  "require": {
    "composer/installers": "^2.0",
    "agency/base-theme": "^1.0"
  }
}
```

Installing `client-a-theme` automatically includes `base-theme` and `timber-library`.

## Directory Naming Conventions

### Default Behavior

Package `agency/base-theme` installs to:
```
web/app/themes/base-theme/
```

### Custom Directory Name

Use `extra.installer-name`:

```json
{
  "name": "agency/base-theme",
  "extra": {
    "installer-name": "agency-base"
  }
}
```

Installs to:
```
web/app/themes/agency-base/
```

**Use Cases:**
- Avoid name conflicts
- Match existing theme directory names
- Clearer directory structure

## Repository Organization Strategies

### Strategy A: Monorepo (Single Repo, Multiple Packages)

```
agency-wordpress-packages/
├── themes/
│   ├── base-theme/
│   │   └── composer.json
│   └── client-themes/
│       ├── client-a/
│       │   └── composer.json
│       └── client-b/
│           └── composer.json
└── plugins/
    ├── utilities/
    │   └── composer.json
    └── features/
        └── composer.json
```

**satis.json:**
```json
{
  "repositories": [
    { "type": "path", "url": "themes/base-theme" },
    { "type": "path", "url": "plugins/utilities" }
  ]
}
```

**Pros:**
- Single repository to manage
- Shared CI/CD pipeline
- Easier for small teams

**Cons:**
- All packages share same version history
- Larger git clone
- Can't version independently

### Strategy B: Multi-Repo (Separate Repos)

```
GitHub Organization: agency
├── base-theme (repo)
├── utilities-plugin (repo)
├── client-a-theme (repo)
└── client-b-theme (repo)
```

**satis.json:**
```json
{
  "repositories": [
    { "type": "vcs", "url": "git@github.com:agency/base-theme.git" },
    { "type": "vcs", "url": "git@github.com:agency/utilities-plugin.git" },
    { "type": "vcs", "url": "git@github.com:agency/client-a-theme.git" }
  ]
}
```

**Pros:**
- Independent versioning
- Cleaner git history per package
- Can restrict access per repo

**Cons:**
- More repos to manage
- Separate CI/CD per repo
- Cross-package changes require multiple PRs

**Recommendation:** Multi-repo for production agencies, monorepo for small teams/personal projects.

## Template Repository

Create a template for new themes/plugins:

**agency/wp-theme-template/composer.json:**
```json
{
  "name": "agency/PACKAGE-NAME",
  "description": "DESCRIPTION",
  "type": "wordpress-theme",
  "version": "0.1.0",
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0"
  },
  "extra": {
    "installer-name": "DIRECTORY-NAME"
  }
}
```

**GitHub Template Repo:** Mark as template, then "Use this template" creates new repos pre-configured.

## Validation Checklist

Before adding to Satis, verify:

- [ ] `composer.json` exists in repository root
- [ ] `"type"` is one of: `wordpress-theme`, `wordpress-plugin`, `wordpress-muplugin`
- [ ] `"composer/installers"` in `require` section
- [ ] At least one git tag exists (for versioned installs)
- [ ] Theme has `style.css` with valid header
- [ ] Plugin has main PHP file with valid header
- [ ] `composer validate` passes without errors

**Validation Command:**
```bash
composer validate --strict
```

## See Also

- [Satis Deployment](satis-deployment.md) - Add these repos to Satis
- [Version Management](../workflows/version-management.md) - Semantic versioning guide
- [Bedrock Configuration](bedrock-configuration.md) - Use these packages in sites
