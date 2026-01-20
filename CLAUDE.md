<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

# Satis - Private Composer Repository

Static Composer repository generator for hosting private PHP packages. This instance serves WordPress themes/plugins for Bedrock projects.

## Documentation

**Project Details:** `openspec/project.md` - Architecture, deployment, WordPress integration

**Setup Guides:** `openspec/guides/` - Complete setup and workflow documentation
- **[Guides Overview](openspec/guides/README.md)** - Start here for Satis + Bedrock setup
- **Setup:** Repository structure, Satis deployment, Bedrock configuration
- **Workflows:** Updating packages, version management, webhooks
- **Architecture:** System overview, authentication methods

## Quick Reference

### Architecture Overview
- **Entry point**: `bin/satis`
- **Builders**: `src/Builder/` (Builder, PackagesBuilder, ArchiveBuilder, WebBuilder)
- **Config schema**: `res/satis-schema.json`
- **Package selection**: `src/PackageSelection/PackageSelection.php`

### Common Commands

**PHP:**
```bash
composer install                 # Install dependencies
composer test                    # Run tests
composer phpstan                 # Static analysis
composer php-cs-fixer-fix        # Fix code style
for d in tools/*; do composer --working-dir=$d install; done  # Setup linting tools
```

**Frontend:**
```bash
bun install                      # Install dependencies (or npm install)
bun run watch                    # Development build with watch
bun run build                    # Production build
bun run prettier                 # Format code
```

**Satis Build:**
```bash
# Full build
php bin/satis build satis.json output/

# Partial update (specific repository)
php bin/satis build --repository-url https://github.com/vendor/repo satis.json output/

# Purge old archives
php bin/satis purge satis.json output/
```

**Docker:**
```bash
docker build -t satis .
docker run --rm -it -v $(pwd):/build -v ~/.composer:/composer satis build satis.json output/
```

### Minimal satis.json
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

### Tech Stack
- PHP 8.3+, Composer 2.x, Symfony Console
- JavaScript (ES6+), Webpack Encore, Bootstrap 5, Sass
- PHPUnit, PHPStan, PHP-CS-Fixer, ESLint, Prettier
- Docker (Alpine-based)

### Key Files
- `composer.json` - PHP dependencies and scripts
- `package.json` - Frontend dependencies and build scripts
- `.php-cs-fixer.dist.php` - PHP code style config
- `phpstan.neon.dist` - Static analysis config
- `webpack.config.js` - Frontend build config