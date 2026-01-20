# Version Management

Semantic versioning strategy and best practices for WordPress packages.

## Semantic Versioning (SemVer)

**Format:** `MAJOR.MINOR.PATCH` (e.g., `2.3.1`)

```
2.3.1
│ │ │
│ │ └─ PATCH: Bug fixes (backward-compatible)
│ └─── MINOR: New features (backward-compatible)
└───── MAJOR: Breaking changes (incompatible)
```

### Version Increment Rules

**MAJOR (2.0.0):**
- Breaking API changes
- Removed features or functions
- Changed function signatures
- Renamed hooks or filters
- Updated minimum PHP/WordPress version (if breaks existing sites)

**MINOR (1.1.0):**
- New features (backward-compatible)
- New functions or hooks
- Deprecated features (still working, marked for removal)
- Performance improvements

**PATCH (1.0.1):**
- Bug fixes only
- Security patches
- Documentation updates
- No functional changes

## WordPress Package Versioning

### Theme Versioning

**Base theme with child themes:**

```
agency/base-theme 1.0.0
├── Initial release
├── 1.0.1 - Bug fix (header alignment)
├── 1.1.0 - New feature (dark mode support)
├── 1.2.0 - New feature (custom widgets)
└── 2.0.0 - Breaking change (new template structure)

agency/client-a-theme 1.0.0 (depends on base-theme ^1.0)
└── Still compatible with base-theme 1.x (not 2.0)
```

**Dependency management:**
```json
{
  "name": "agency/client-a-theme",
  "require": {
    "agency/base-theme": "^1.0"
  }
}
```

When base-theme reaches 2.0.0, client themes must explicitly update:
```bash
composer require "agency/base-theme:^2.0"
```

### Plugin Versioning

**Utility plugin with breaking changes:**

```
agency/utilities 1.0.0
├── function get_option_value($key)
├── function render_component($name)
└── hook: agency_before_render

agency/utilities 2.0.0
├── function getOptionValue($key)  // Renamed (camelCase)
├── function render($component, $args)  // Changed signature
└── hook: agency/before_render  // Changed namespace
```

**Migration path:**
```php
// 1.x (deprecated but still works)
if (function_exists('get_option_value')) {
    $value = get_option_value('key');  // Old way
}

// 2.0 (new way)
use Agency\Utilities\Options;
$value = Options::get('key');
```

## Version Constraints

### Composer Constraint Operators

| Operator | Meaning | Example | Allows |
|----------|---------|---------|--------|
| `^1.2.3` | Compatible with 1.x | `^1.2.3` | ≥1.2.3 <2.0.0 |
| `~1.2.3` | Approximate version | `~1.2.3` | ≥1.2.3 <1.3.0 |
| `>=1.2 <2.0` | Range | `>=1.2.0 <1.5.0` | 1.2.0 to 1.4.9 |
| `1.2.*` | Wildcard | `1.2.*` | 1.2.0 to 1.2.99 |
| `1.2.3` | Exact | `1.2.3` | Only 1.2.3 |
| `*` | Any | `*` | Latest (avoid) |

### Recommended Constraints

**Shared packages (stable):**
```json
{
  "require": {
    "agency/base-theme": "^1.0",
    "agency/utilities": "^1.0"
  }
}
```

**Client-specific packages:**
```json
{
  "require": {
    "agency/client-a-theme": "~2.1.0"
  }
}
```

**Experimental features:**
```json
{
  "require": {
    "agency/experimental-plugin": ">=1.0 <2.0"
  }
}
```

## Pre-Release Versions

### Format

```
1.0.0-alpha.1    # First alpha
1.0.0-alpha.2    # Second alpha
1.0.0-beta.1     # First beta
1.0.0-rc.1       # Release candidate
1.0.0            # Stable release
```

### Usage

**Development:**
```bash
git tag -a v1.0.0-alpha.1 -m "First alpha release"
```

**Client installation:**
```json
{
  "require": {
    "agency/base-theme": "1.0.0-alpha.1"
  },
  "minimum-stability": "alpha"
}
```

**Stability levels:** `dev` < `alpha` < `beta` < `RC` < `stable`

## Branch-Based Versions

### Format

Branches become `dev-<branch-name>`:

```
main → dev-main
develop → dev-develop
feature/new-header → dev-feature/new-header
```

### Usage

**Development environment:**
```json
{
  "require": {
    "agency/base-theme": "dev-develop"
  }
}
```

**⚠️ Warning:** Dev versions can change without notice. Not recommended for production.

## Version Lifecycle

### Example Timeline

```
1.0.0 (2024-01-01) - Initial release
  ├── 1.0.1 (2024-01-15) - Security fix
  ├── 1.0.2 (2024-02-01) - Bug fixes
  ├── 1.1.0 (2024-03-01) - New features
  ├── 1.2.0 (2024-05-01) - More features
  └── 1.2.1 (2024-05-15) - Bug fix

2.0.0-beta.1 (2024-06-01) - Beta release
2.0.0-rc.1 (2024-06-15) - Release candidate
2.0.0 (2024-07-01) - Major release

1.3.0 (2024-07-15) - Backport features to 1.x
1.3.1 (2024-08-01) - Bug fixes (1.x maintained for 6 months)
```

**Support windows:**
- **Current major:** Full support
- **Previous major:** Security fixes for 6-12 months
- **Older versions:** Unmaintained

## Deprecation Policy

### Marking Features as Deprecated

**PHP DocBlock:**
```php
/**
 * Get option value.
 *
 * @deprecated 1.5.0 Use Options::get() instead
 * @see \Agency\Utilities\Options::get()
 *
 * @param string $key
 * @return mixed
 */
function get_option_value($key) {
    _deprecated_function(__FUNCTION__, '1.5.0', 'Options::get()');
    return Options::get($key);
}
```

**WordPress deprecation:**
```php
if (function_exists('_deprecated_function')) {
    _deprecated_function(__FUNCTION__, '1.5.0', 'Options::get()');
}
```

### Deprecation Timeline

```
1.4.0 - Feature introduced
1.5.0 - Feature marked deprecated (still works)
1.6.0 - Deprecation warning shown
2.0.0 - Feature removed (breaking change)
```

**Minimum deprecation period:** 2 minor versions or 6 months.

## Composer Lock File

### Understanding composer.lock

**composer.json (requirements):**
```json
{
  "require": {
    "agency/base-theme": "^1.0"
  }
}
```

**composer.lock (exact versions):**
```json
{
  "packages": [
    {
      "name": "agency/base-theme",
      "version": "1.2.3"
    }
  ]
}
```

### Lock File Workflow

**Development:**
```bash
composer update  # Updates packages, writes new composer.lock
git add composer.lock
git commit -m "chore: update dependencies"
```

**Production:**
```bash
composer install  # Installs exact versions from composer.lock
# Never run `composer update` on production!
```

### When to Update Lock File

**Update specific package:**
```bash
composer update agency/base-theme
# Updates only base-theme and its dependencies
```

**Update all packages:**
```bash
composer update
# Updates all packages to latest compatible versions
```

**Check for outdated packages:**
```bash
composer outdated "agency/*"
```

## Version Pinning Strategies

### Strategy A: Pin Shared Packages

**For consistent deployments across multiple sites:**

```json
{
  "require": {
    "agency/base-theme": "1.2.3",
    "agency/utilities": "1.1.0"
  }
}
```

**Update manually:**
```bash
composer require "agency/base-theme:1.3.0"
```

### Strategy B: Flexible Constraints

**For automatic minor updates:**

```json
{
  "require": {
    "agency/base-theme": "^1.2",
    "agency/utilities": "^1.1"
  }
}
```

**Update regularly:**
```bash
composer update "agency/*"
```

### Strategy C: Mixed Approach

**Pin stable, allow updates for active development:**

```json
{
  "require": {
    "agency/base-theme": "1.2.3",
    "agency/client-theme": "^2.0",
    "agency/experimental": "dev-main"
  }
}
```

## Breaking Change Migration

### Example: Renaming Functions

**Version 1.9.0 (prepare for 2.0):**
```php
// Old function (deprecated)
function get_option_value($key) {
    _deprecated_function(__FUNCTION__, '1.9.0', 'Options::get()');
    return \Agency\Utilities\Options::get($key);
}

// New function (recommended)
class Options {
    public static function get($key) {
        // Implementation
    }
}
```

**Version 2.0.0 (breaking change):**
```php
// Old function removed
// Only new function available

class Options {
    public static function get($key) {
        // Implementation
    }
}
```

**Client migration:**
```php
// Before (1.x)
$value = get_option_value('key');

// After (2.0+)
use Agency\Utilities\Options;
$value = Options::get('key');
```

## Changelog Format

**CHANGELOG.md:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dark mode support

### Changed
- Updated header component styling

## [1.2.0] - 2024-03-15

### Added
- New widget area for footer
- Custom post type support

### Changed
- Improved mobile navigation performance

### Fixed
- Header alignment on tablet devices

### Deprecated
- `get_option_value()` function (use `Options::get()` instead)

## [1.1.0] - 2024-02-01

### Added
- Responsive header component
- Mobile navigation menu

### Fixed
- Z-index issues with dropdown menus

## [1.0.1] - 2024-01-15

### Fixed
- Security patch for XSS vulnerability

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Base theme structure
- Template hierarchy
```

## See Also

- [Updating Packages](updating-packages.md) - Release workflow
- [Repository Structure](../setup/repository-structure.md) - Package setup
- [Bedrock Configuration](../setup/bedrock-configuration.md) - Version constraints
