# Project Context

## Purpose

Satis is a static Composer repository generator for hosting private PHP packages. This instance will serve as a private package repository for WordPress themes and plugins compatible with Bedrock architecture.

**Use Case:** Host proprietary WordPress components for internal projects without relying on external paid services.

## Tech Stack

- **Backend:** PHP 8.3+ with Composer 2.x
- **Frontend:** JavaScript (ES6+), Symfony Webpack Encore, Bootstrap 5, Sass
- **Testing:** PHPUnit 11.5+
- **Linting:** PHP-CS-Fixer, PHPStan, ESLint, Prettier
- **Deployment:** Docker (multi-stage Alpine-based) on Coolify

## Core Architecture Details

### Builder Pattern Implementation

The build process uses a coordinated multi-builder pattern in `src/Builder/`:

1. **Builder.php** - Main orchestrator
   - Coordinates all builders in sequence
   - Manages build configuration and output directory
   - Handles build events and logging

2. **PackagesBuilder.php** - Repository metadata generator
   - Scans VCS repositories for Composer packages
   - Generates `packages.json` with all package versions
   - Implements partial update optimization via package name or repository URL

3. **ArchiveBuilder.php** - Package distribution creator
   - Creates downloadable archives (zip/tar) of package releases
   - Supports CDN prefix URLs for distribution
   - Implements whitelist/blacklist filtering
   - Handles archive checksums and metadata

4. **WebBuilder.php** - HTML interface generator
   - Renders Twig templates for web browsing interface
   - Generates index and per-package pages
   - Supports custom templates via configuration

Each builder implements `BuilderInterface` with `dump()` method for independent execution.

### Package Selection Logic

`src/PackageSelection/PackageSelection.php` implements filtering strategy:

- **require-all**: Selects all versions from all configured repositories
- **require**: Cherry-picks specific packages with version constraints
- **require-dependencies**: Resolves and includes transitive dependencies
- **require-dev-dependencies**: Includes development dependencies
- **blacklist**: Excludes specific packages/versions
- **abandoned**: Marks packages as deprecated with optional replacement

### Configuration Schema

Full schema available in `res/satis-schema.json`. Key configuration sections:

**repositories**: Array of Composer repository definitions
- Supports: VCS (git, svn, hg), composer, package, path types
- Named repositories enable efficient partial updates

**archive**: Package distribution configuration
- `directory`: Output location for archives (inside output-dir)
- `format`: zip (default) or tar
- `prefix-url`: CDN or custom host for downloads (defaults to homepage)
- `skip-dev`: Exclude development branches from archives
- `absolute-directory`: Alternative absolute path for archives
- `whitelist`/`blacklist`: Package filtering with wildcard support
- `checksum`: SHA1 checksum generation (enabled by default)

**output**: Web interface configuration
- `output-dir`: Base directory for all generated files
- `output-html`: Enable/disable HTML generation
- `twig-template`: Custom template path
- `providers`: Split metadata into per-package files (for large repos)

## Satis Configuration Examples

### Minimal Configuration
```json
{
    "name": "My Repository",
    "homepage": "https://packages.example.org",
    "repositories": [
        { "type": "vcs", "url": "https://github.com/mycompany/repo" }
    ],
    "require-all": true
}
```

### Cherry-Pick Packages with Version Constraints
```json
{
    "repositories": [
        { "type": "vcs", "url": "https://github.com/mycompany/repo" }
    ],
    "require": {
        "company/package": "*",
        "company/package2": "^2.0",
        "company/package3": "dev-master"
    }
}
```

### With Archives for Offline/CDN Distribution
```json
{
    "archive": {
        "directory": "dist",
        "format": "tar",
        "prefix-url": "https://cdn.example.org",
        "skip-dev": true,
        "checksum": true
    }
}
```

### With Dependency Resolution
```json
{
    "repositories": [
        { "type": "composer", "url": "https://packagist.org" },
        { "type": "vcs", "url": "https://github.com/mycompany/private" }
    ],
    "require": {
        "mycompany/app": "^1.0"
    },
    "require-dependencies": true,
    "require-dev-dependencies": false
}
```

### Named Repositories for Efficient Partial Updates
```json
{
    "repositories": [
        {
            "name": "company/package1",
            "type": "vcs",
            "url": "https://github.com/company/package1"
        },
        {
            "name": "company/package2",
            "type": "vcs",
            "url": "https://github.com/company/package2"
        }
    ],
    "require-all": true
}
```

## Building Satis Output

### Full Build
```bash
php bin/satis build <config-file> <output-dir>
# Example: php bin/satis build satis.json web/
```

### Partial Updates (Faster Rebuilds)

**By Package Name** (still scans all repos):
```bash
php bin/satis build satis.json web/ vendor/package1 vendor/package2
```

**By Repository URL** (most efficient):
```bash
php bin/satis build --repository-url https://github.com/vendor/repo satis.json web/
```

**By Named Repository** (requires `name` in repository config):
```bash
# Only scans the specific repository
php bin/satis build satis.json web/ company/package1
```

### Purging Old Archives
```bash
php bin/satis purge <config-file> <output-dir>
# Example: php bin/satis purge satis.json web/
```

⚠️ **Warning:** Only purge if you're certain no projects reference old archives in their `composer.lock` files.

## Frontend Assets

### Build Process
- **Source:** `views/assets/js/app.js` and `views/assets/css/style.scss`
- **Output:** `views/build/` (app.js, style.css)
- **Bundler:** Symfony Webpack Encore with Babel transpilation
- **Optimization:** PurgeCSS removes unused CSS in production builds
- **IE11 Support:** Output environment configured for legacy browser compatibility

### Template System
- **Engine:** Twig 3.x
- **Templates:** `views/index.html.twig`, `views/package.html.twig`
- **Customization:** Override via `twig-template` config option

**Available Template Variables:**
- `{{ name }}` - Repository name
- `{{ description }}` - Repository description
- `{{ url }}` - Homepage URL
- `{{ packages }}` - Array of package metadata

## Testing Strategy

### Running Tests
```bash
# All tests with coverage
composer test

# Specific test class
vendor/bin/phpunit tests/Builder/PackagesBuilderTest.php

# Specific test method
vendor/bin/phpunit --filter testPartialUpdate tests/Builder/

# Coverage report
vendor/bin/phpunit --coverage-html coverage/
```

### Test Structure
- **Location:** `tests/` mirrors `src/` structure
- **Framework:** PHPUnit 11.5+
- **Filesystem Mocking:** `mikey179/vfsstream` for virtual filesystem testing
- **Strategy:** Unit tests for builders, integration tests for full build process

### CI Test Matrix
- PHP versions: 8.3, 8.4, 8.5
- Stability: prefer-lowest, prefer-stable
- Coverage: Xdebug enabled on CI

## Code Quality Standards

### PHP Standards
- **PSR-12 Compliance:** Enforced via PHP-CS-Fixer
- **Configuration:** `.php-cs-fixer.dist.php`
- **Commands:**
  - Check: `composer php-cs-fixer`
  - Fix: `composer php-cs-fixer-fix`
  - Direct: `tools/php-cs-fixer/vendor/bin/php-cs-fixer fix`

### Static Analysis
- **Tool:** PHPStan
- **Configuration:** `phpstan.neon.dist`
- **Baseline:** `phpstan-baseline.neon` (accepted warnings)
- **Commands:**
  - Run: `composer phpstan`
  - Direct: `tools/phpstan/vendor/bin/phpstan`

### JavaScript Standards
- **Linter:** ESLint 9+ with flat config (`eslint.config.js`)
- **Formatter:** Prettier 3.8+
- **Pre-commit:** Husky + lint-staged automatically enforce on commit
- **Commands:**
  - Lint: `bun run eslint`
  - Format: `bun run prettier`
  - Format check: `bun run prettier:ci`

### Tooling Architecture
PHP linting tools are isolated in `tools/*/` to avoid dependency conflicts:
```bash
# Install all tooling
for d in tools/*; do composer --working-dir=$d install; done
```

## Git Workflow

### CI/CD Pipelines

**GitHub Actions** (`.github/workflows/`):

1. **ci.yaml** - PHPUnit test matrix
   - PHP 8.3, 8.4, 8.5
   - prefer-lowest and prefer-stable
   - Xdebug coverage enabled

2. **lint.yaml** - Code quality checks
   - PHP-CS-Fixer validation
   - PHPStan static analysis
   - ESLint + Prettier validation

3. **docker.yaml** - Container builds
   - Multi-platform builds (linux/amd64, linux/arm64)
   - Pushes to Docker Hub and GitHub Container Registry

### Commit Conventions
Standard Conventional Commits recommended for clear changelog generation.

## Deployment Context (Coolify)

### Deployment Strategy

**Purpose:** Host private WordPress themes/plugins repository for Bedrock-based projects.

**Infrastructure:**
- **Platform:** Coolify (self-hosted PaaS)
- **Web Server:** Nginx or Apache serving `output/` directory
- **Build Automation:** Cron job for periodic repository updates
- **Authentication:** HTTP Basic Auth or token-based access control

### Deployment Configuration

**Output Directory Structure:**
```
output/
├── index.html          # Web interface (if output-html: true)
├── packages.json       # Main package metadata
├── include/            # Split package metadata (if providers: true)
├── dist/               # Package archives (if archive configured)
└── p2/                 # Composer v2 metadata URLs
```

**Web Server Configuration:**
- Document root: `/path/to/satis/output/`
- Index files: `index.html`, `packages.json`
- MIME type for `.json`: `application/json`

**Cron Job Example:**
```bash
# Update repository every hour
0 * * * * cd /path/to/satis && php bin/satis build satis.json output/ --no-interaction >> /var/log/satis-build.log 2>&1
```

**Webhook Integration:**
```bash
# Partial update on git push webhook
php bin/satis build --repository-url $WEBHOOK_REPO_URL satis.json output/ --no-interaction
```

### Security Considerations

**Credentials Management:**
- Never commit `auth.json` (contains VCS credentials)
- Use environment variables: `COMPOSER_AUTH` JSON for runtime credentials
- Mount secrets via Coolify environment variables or Docker secrets
- For GitHub private repos: Configure SSH key access

**Access Control:**
- Implement HTTP Basic Auth for private repository access
- Use token-based auth via custom HTTP headers for API access
- Consider IP whitelisting for additional security

**Build Isolation:**
- Run builds with `--no-interaction` flag (prevents interactive prompts)
- Use non-root user for Docker builds: `--user $(id -u):$(id -g)`
- Separate build and web serving directories if possible

### Archive Hosting Strategy

**Option 1: Same Host**
```json
{
    "archive": {
        "directory": "dist",
        "format": "tar"
    }
}
```

**Option 2: CDN Distribution**
```json
{
    "archive": {
        "directory": "dist",
        "format": "tar",
        "prefix-url": "https://cdn.example.org/satis"
    }
}
```
Then sync `output/dist/` to CDN after each build.

**Option 3: S3/Object Storage**
```json
{
    "archive": {
        "absolute-directory": "/mnt/s3-bucket/satis/dist",
        "prefix-url": "https://s3.amazonaws.com/my-bucket/satis"
    }
}
```

## WordPress Bedrock Integration

### Purpose
Bedrock is a modern WordPress stack that uses Composer for dependency management. This Satis instance serves as a private repository for proprietary themes and plugins.

### Client Configuration

**Add to Bedrock project's `composer.json`:**
```json
{
    "repositories": [
        {
            "type": "composer",
            "url": "https://satis.example.org/"
        }
    ],
    "require": {
        "your-vendor/custom-theme": "^1.0",
        "your-vendor/custom-plugin": "^2.0"
    },
    "extra": {
        "installer-paths": {
            "web/app/themes/{$name}/": ["type:wordpress-theme"],
            "web/app/plugins/{$name}/": ["type:wordpress-plugin"],
            "web/app/mu-plugins/{$name}/": ["type:wordpress-muplugin"]
        }
    }
}
```

**With Authentication:**
```json
{
    "repositories": [
        {
            "type": "composer",
            "url": "https://satis.example.org/",
            "options": {
                "http": {
                    "header": ["Authorization: Bearer YOUR_TOKEN"]
                }
            }
        }
    ]
}
```

### WordPress Package Structure

**Theme Example:**
```json
{
    "name": "your-vendor/custom-theme",
    "description": "Custom WordPress theme",
    "type": "wordpress-theme",
    "require": {
        "composer/installers": "^2.0"
    },
    "version": "1.0.0"
}
```

**Plugin Example:**
```json
{
    "name": "your-vendor/custom-plugin",
    "description": "Custom WordPress plugin",
    "type": "wordpress-plugin",
    "require": {
        "composer/installers": "^2.0",
        "php": ">=8.0"
    }
}
```

**MU-Plugin Example:**
```json
{
    "name": "your-vendor/custom-mu-plugin",
    "type": "wordpress-muplugin",
    "require": {
        "composer/installers": "^2.0"
    }
}
```

### Valid Package Types
- `wordpress-theme` - Installed to `web/app/themes/`
- `wordpress-plugin` - Installed to `web/app/plugins/`
- `wordpress-muplugin` - Installed to `web/app/mu-plugins/`

### Version Control Best Practices

**Semantic Versioning:**
- Use git tags: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Satis automatically detects tags as package versions
- Branch names like `dev-main` also work for development versions

**Composer Installers:**
All WordPress packages MUST require `composer/installers` to enable proper installation paths in Bedrock projects.

## Domain Context

### Composer Ecosystem
- **Packagist:** Public Composer repository (default)
- **Satis:** Static repository generator for private packages
- **Private Packagist:** Commercial hosted alternative (not used here)

### Static vs. Dynamic Repositories
- **Static (Satis):** Pre-built `packages.json`, fast, no server-side processing
- **Dynamic:** On-demand package resolution, requires application server

### WordPress Bedrock Stack
- **Bedrock:** Modern WordPress boilerplate using Composer
- **Composer Installers:** Maps package types to WordPress directory structure
- **Environment-based configuration:** 12-factor app methodology

## Important Constraints

### PHP Version Requirements
- **Minimum:** PHP 8.3 (as per `composer.json`)
- **Extensions Required:** ext-zip (archive creation)
- **Recommended:** git, svn, hg for VCS repository support

### Docker Constraints
- **Base Image:** php:8-cli-alpine (minimalist, production-ready)
- **Multi-stage Build:** Separates build and runtime dependencies
- **VCS Tools:** git, mercurial, subversion pre-installed in final image

### Build Performance
- **Full Build:** Can be slow for large repositories (scans all VCS repos)
- **Partial Updates:** Use named repositories or `--repository-url` for efficiency
- **Archive Generation:** Resource-intensive for large packages

### Composer Constraints
- **Memory:** Large dependency trees may require increased PHP memory_limit
- **Timeout:** VCS cloning may timeout on slow connections (configure `config.process-timeout`)
- **Authentication:** GitHub API rate limits apply (use authentication token)

## External Dependencies

### VCS Platforms
- **GitHub:** Primary VCS for private repositories (requires SSH key or token)
- **GitLab:** Supported via VCS repository type
- **Bitbucket:** Supported via VCS repository type
- **Self-hosted Git:** Supported via SSH or HTTPS

### Composer Repositories
- **Packagist.org:** Public PHP package repository (can be included as dependency source)
- **Custom Composer Repos:** Other Satis instances can be nested

### Build Tools
- **Composer 2.x:** Dependency resolution and package management
- **Git/Mercurial/SVN:** VCS clients for repository cloning
- **7zip:** Archive extraction support (included in Docker image)

### Frontend Build Dependencies
- **Node.js/Bun:** JavaScript package management and build tooling
- **Webpack Encore:** Asset compilation and optimization
- **Bootstrap 5:** UI framework for web interface
- **PurgeCSS:** Removes unused CSS in production builds
