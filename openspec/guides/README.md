# Satis + Bedrock WordPress Documentation

Complete guide for managing WordPress themes and plugins across multiple Bedrock sites using Satis.

## Quick Start

New to this setup? Start here:

1. **[Architecture Overview](architecture/overview.md)** - Understand the complete system
2. **[Repository Structure](setup/repository-structure.md)** - Prepare your themes/plugins
3. **[Satis Deployment](setup/satis-deployment.md)** - Deploy Satis on Coolify
4. **[Bedrock Configuration](setup/bedrock-configuration.md)** - Configure client sites

## Setup Guides

**Initial Setup:**
- [Repository Structure](setup/repository-structure.md) - Structure themes/plugins with composer.json
- [Satis Deployment](setup/satis-deployment.md) - Deploy with Coolify using docker-compose
- [Bedrock Configuration](setup/bedrock-configuration.md) - Configure client sites to use Satis
- [Authentication Setup](architecture/authentication.md) - Secure your private repository

## Workflow Guides

**Daily Operations:**
- [Updating Packages](workflows/updating-packages.md) - Release new versions of themes/plugins
- [Version Management](workflows/version-management.md) - Semantic versioning and git tags
- [Webhook Configuration](workflows/webhooks.md) - Automated rebuilds on git push

## Architecture Guides

**Deep Dives:**
- [System Architecture](architecture/overview.md) - Complete infrastructure overview
- [Authentication Methods](architecture/authentication.md) - HTTP Basic Auth, IP whitelisting

## Use Cases

### Scenario: Agency Managing Multiple Client Sites

**Goal:** Share a base theme and utility plugins across 10+ Bedrock WordPress sites.

**Solution:**
1. Create separate git repos for `agency/base-theme` and `agency/utilities-plugin`
2. Deploy Satis to host these packages privately
3. Each client site includes your Satis repository in their `composer.json`
4. Update base theme → tag new version → all clients run `composer update`

See [Architecture Overview](architecture/overview.md) for complete diagram.

### Scenario: Commercial Plugin Management

**Goal:** Use premium plugins (ACF Pro, Gravity Forms) with Composer.

**Options:**
- **Option A:** Use plugin's official Composer repository (if available)
  - Example: ACF Pro offers official Composer support
  - Add repository to `composer.json` with license key
- **Option B:** Use SatisPress WordPress plugin to generate Composer repository
  - Install SatisPress on a WordPress site
  - Upload/update premium plugins via WordPress admin
  - SatisPress auto-generates Composer repository
- **Option C:** Package manually and host in Satis (requires license compliance)
  - Create wrapper package with `composer.json`
  - Include plugin ZIP in repository
  - Ensure compliance with plugin license terms

## Best Practices

| Practice | Rationale | Guide |
|----------|-----------|-------|
| Semantic versioning | Clients get compatible updates with `^1.0` constraints | [Version Management](workflows/version-management.md) |
| Archive ZIP files | Faster installs, no git clone on production | [Satis Deployment](setup/satis-deployment.md) |
| Separate repos per package | Independent versioning, cleaner history | [Repository Structure](setup/repository-structure.md) |
| Webhook + cron combo | Immediate + periodic rebuilds | [Webhooks](workflows/webhooks.md) |
| HTTP Basic Auth | Simple, native Composer support | [Authentication](architecture/authentication.md) |
| Read-only deploy keys | Satis only needs read access | [Satis Deployment](setup/satis-deployment.md) |

## Troubleshooting

**Common Issues:**

**"Could not find package agency/base-theme"**
- Ensure package has valid `composer.json` with `type: wordpress-theme`
- Check Satis build logs for repository scanning errors
- Verify git tags are pushed (`git push --tags`)

**"Failed to download agency/base-theme from dist"**
- Archive generation may have failed during Satis build
- Check `archive.directory` configuration in `satis.json`
- Verify web server can serve files from archive directory

**Authentication failures**
- Confirm `auth.json` has correct credentials for Satis host
- Check HTTP Basic Auth is configured on Satis server
- Verify permissions on `.htpasswd` file

See individual guides for detailed troubleshooting sections.

## Reference

- **Satis Documentation:** https://getcomposer.org/doc/articles/handling-private-packages-with-satis.md
- **Bedrock Documentation:** https://roots.io/bedrock/
- **Composer Installers:** https://github.com/composer/installers
- **rebelinblue/satis Docker:** https://github.com/rebelinblue/satis
