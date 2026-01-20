# Bedrock Configuration

Configure Bedrock WordPress sites to use your private Satis repository.

## Prerequisites

- Satis server deployed and accessible
- HTTP Basic Auth credentials (if enabled)
- Packages published to Satis with valid git tags

## Basic Configuration

### Add Satis Repository

Edit your Bedrock project's `composer.json`:

```json
{
  "name": "agency/client-a-website",
  "type": "project",
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com"
    },
    {
      "type": "composer",
      "url": "https://wpackagist.org",
      "only": ["wpackagist-plugin/*", "wpackagist-theme/*"]
    }
  ],
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0",
    "roots/bedrock-autoloader": "^1.0",
    "roots/bedrock-disallow-indexing": "^2.0",
    "roots/wordpress": "6.8.1",
    "roots/wp-config": "1.0.0",
    "roots/wp-password-bcrypt": "1.1.0",

    "agency/base-theme": "^1.0",
    "agency/utilities": "^1.0",

    "wpackagist-plugin/wordpress-seo": "^23.0"
  },
  "extra": {
    "installer-paths": {
      "web/app/mu-plugins/{$name}/": ["type:wordpress-muplugin"],
      "web/app/plugins/{$name}/": ["type:wordpress-plugin"],
      "web/app/themes/{$name}/": ["type:wordpress-theme"]
    },
    "wordpress-install-dir": "web/wp"
  }
}
```

### Install Packages

```bash
composer install
```

**Expected output:**
```
Loading composer repositories with package information
Installing dependencies (including require-dev)
Package operations: 25 installs, 0 updates, 0 removals
  - Installing agency/base-theme (1.0.0): Downloading (100%)
  - Installing agency/utilities (1.0.0): Downloading (100%)
  ...
```

**Verify installation:**
```bash
ls -la web/app/themes/
# Should show: base-theme/

ls -la web/app/plugins/
# Should show: utilities/
```

## Authentication Setup

### Option A: HTTP Basic Auth (Recommended)

Create `auth.json` in project root (same directory as `composer.json`):

```json
{
  "http-basic": {
    "packages.youragency.com": {
      "username": "composer",
      "password": "your-secure-password"
    }
  }
}
```

**⚠️ Important:** Add to `.gitignore`:
```bash
echo "auth.json" >> .gitignore
```

**Never commit credentials to git!**

### Option B: Environment Variable

**For CI/CD pipelines:**

```bash
export COMPOSER_AUTH='{"http-basic":{"packages.youragency.com":{"username":"composer","password":"password"}}}'

composer install --no-interaction
```

**GitHub Actions example:**
```yaml
- name: Install Composer Dependencies
  env:
    COMPOSER_AUTH: ${{ secrets.COMPOSER_AUTH }}
  run: composer install --no-dev --optimize-autoloader
```

### Option C: Token-Based Auth

**If Satis configured with token auth:**

```json
{
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com",
      "options": {
        "http": {
          "header": ["Authorization: Bearer YOUR_API_TOKEN"]
        }
      }
    }
  ]
}
```

## Repository Priority

**Order matters!** Composer checks repositories in order:

```json
{
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com"
    },
    {
      "type": "composer",
      "url": "https://wpackagist.org",
      "only": ["wpackagist-plugin/*", "wpackagist-theme/*"]
    }
  ]
}
```

**Why this order:**
1. Check Satis first for agency packages
2. Fall back to WPackagist for public plugins

**Using `only` filter:** Prevents WPackagist from being checked for agency packages (performance optimization).

## Version Constraints

### Recommended Constraints

```json
{
  "require": {
    "agency/base-theme": "^1.0",
    "agency/utilities": "^1.0",
    "agency/client-specific-plugin": "~2.1.0"
  }
}
```

**Constraint Types:**

| Constraint | Meaning | Example | Allows |
|------------|---------|---------|--------|
| `^1.0` | Compatible with 1.x | `^1.2.3` | 1.2.3, 1.3.0, 1.9.9 (not 2.0.0) |
| `~1.2` | Approximate version | `~1.2.3` | 1.2.3, 1.2.9 (not 1.3.0) |
| `>=1.0 <2.0` | Range | `>=1.2.0 <1.5.0` | 1.2.0 to 1.4.9 |
| `1.2.3` | Exact version | `1.2.3` | Only 1.2.3 |
| `*` | Any version | `*` | Latest version (avoid in production) |
| `dev-main` | Branch | `dev-develop` | Latest commit from branch |

**Best Practices:**
- Use `^` for shared packages (allows minor updates)
- Use `~` for client-specific packages (more restrictive)
- Never use `*` or `dev-*` in production

## Multi-Site Configuration

### Shared Base Configuration

**Create `composer-base.json`:**
```json
{
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com"
    },
    {
      "type": "composer",
      "url": "https://wpackagist.org",
      "only": ["wpackagist-plugin/*", "wpackagist-theme/*"]
    }
  ],
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0",
    "roots/bedrock-autoloader": "^1.0",
    "roots/wordpress": "6.8.1",

    "agency/base-theme": "^1.0",
    "agency/utilities": "^1.0"
  }
}
```

### Client A (extends base)

**`composer.json`:**
```json
{
  "name": "agency/client-a",
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com"
    },
    {
      "type": "composer",
      "url": "https://wpackagist.org",
      "only": ["wpackagist-plugin/*"]
    }
  ],
  "require": {
    "php": ">=8.1",
    "composer/installers": "^2.0",
    "roots/bedrock-autoloader": "^1.0",
    "roots/wordpress": "6.8.1",

    "agency/base-theme": "^1.0",
    "agency/utilities": "^1.0",
    "agency/client-a-theme": "^2.0",

    "wpackagist-plugin/wordpress-seo": "^23.0"
  }
}
```

**Maintenance script** to sync versions:
```bash
#!/bin/bash
# update-all-sites.sh

sites=("client-a" "client-b" "client-c")

for site in "${sites[@]}"; do
  echo "Updating $site..."
  cd "$site"
  composer update "agency/*" --with-dependencies
  cd ..
done
```

## Development vs Production

### Development Environment

**composer.json:**
```json
{
  "require-dev": {
    "roave/security-advisories": "dev-latest",
    "squizlabs/php_codesniffer": "^3.7"
  },
  "config": {
    "optimize-autoloader": false,
    "classmap-authoritative": false
  }
}
```

**Install:**
```bash
composer install
```

### Production Environment

**Deploy script:**
```bash
composer install \
  --no-dev \
  --optimize-autoloader \
  --classmap-authoritative \
  --no-interaction
```

**Flags explained:**
- `--no-dev`: Skip development dependencies
- `--optimize-autoloader`: Generate optimized autoloader
- `--classmap-authoritative`: Don't scan filesystem (faster)
- `--no-interaction`: No prompts (for CI/CD)

## Updating Packages

### Update Single Package

```bash
composer update agency/base-theme
```

### Update All Agency Packages

```bash
composer update "agency/*"
```

### Update All Packages

```bash
composer update
```

**⚠️ Warning:** May update WordPress core and public plugins. Use with caution in production.

### Check for Updates (dry-run)

```bash
composer outdated "agency/*"
```

**Output:**
```
agency/base-theme  1.0.0  1.2.0  Base theme
agency/utilities   1.0.0  1.1.0  Utilities plugin
```

## Dependency Tree

### View Why Package is Installed

```bash
composer why agency/base-theme
```

**Output:**
```
agency/client-a  requires  agency/base-theme (^1.0)
```

### Show Full Dependency Tree

```bash
composer show --tree
```

### Validate Configuration

```bash
composer validate
```

**Should output:**
```
./composer.json is valid
```

## Troubleshooting

### "Could not find package agency/base-theme"

**Causes:**
1. Package not published to Satis
2. Satis not in `repositories` section
3. Authentication failure

**Debug:**
```bash
# Test Satis access
curl -u composer:password https://packages.youragency.com/packages.json

# Check if package exists
curl -u composer:password https://packages.youragency.com/packages.json | jq '.packages["agency/base-theme"]'

# Verbose composer output
composer update agency/base-theme -vvv
```

### "Your requirements could not be resolved"

**Causes:**
1. Version constraint impossible to satisfy
2. PHP version mismatch
3. Dependency conflict

**Debug:**
```bash
# Show why requirement fails
composer why-not agency/base-theme 2.0

# Simulate update without installing
composer update --dry-run
```

### Downloads are Very Slow

**Cause:** Not using archives, Composer is cloning git repos

**Fix:** Ensure Satis has `archive` configured and set preferred install:

```json
{
  "config": {
    "preferred-install": {
      "agency/*": "dist",
      "*": "dist"
    }
  }
}
```

### Authentication Loops

**Symptom:** Composer repeatedly asks for password

**Fix:**
```bash
# Store credentials globally (not recommended for production)
composer config --global http-basic.packages.youragency.com composer password

# Or use auth.json (recommended)
cat > auth.json <<EOF
{
  "http-basic": {
    "packages.youragency.com": {
      "username": "composer",
      "password": "password"
    }
  }
}
EOF
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.1'

      - name: Install Dependencies
        env:
          COMPOSER_AUTH: ${{ secrets.COMPOSER_AUTH }}
        run: |
          composer install --no-dev --optimize-autoloader --no-interaction

      - name: Deploy to Server
        run: |
          rsync -avz --exclude='.git' ./ user@server:/var/www/site/
```

**GitHub Secret `COMPOSER_AUTH`:**
```json
{"http-basic":{"packages.youragency.com":{"username":"composer","password":"your-password"}}}
```

### GitLab CI

```yaml
deploy:
  image: composer:latest
  stage: deploy
  before_script:
    - echo "$COMPOSER_AUTH" > auth.json
  script:
    - composer install --no-dev --optimize-autoloader --no-interaction
    - rsync -avz ./ user@server:/var/www/site/
  only:
    - main
```

## Performance Optimization

### Composer Settings

```json
{
  "config": {
    "optimize-autoloader": true,
    "classmap-authoritative": true,
    "apcu-autoloader": true,
    "preferred-install": "dist",
    "sort-packages": true,
    "platform": {
      "php": "8.1"
    }
  }
}
```

### Cache Configuration

```bash
# Set cache directory
composer config cache-dir /path/to/cache

# Clear cache
composer clear-cache
```

## See Also

- [Repository Structure](repository-structure.md) - Prepare packages for Bedrock
- [Updating Packages](../workflows/updating-packages.md) - Release workflow
- [Version Management](../workflows/version-management.md) - Semantic versioning
