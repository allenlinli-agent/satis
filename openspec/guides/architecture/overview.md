# Architecture Overview

Complete infrastructure diagram and component interaction for Satis + Bedrock WordPress sites.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Your Infrastructure                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────┐         ┌──────────────────────────────────┐     │
│  │  Satis Server         │         │  GitHub/GitLab                   │     │
│  │  (Coolify Container)  │◄────────│  Private Repositories            │     │
│  │                       │ webhook │                                  │     │
│  │  • packages.json      │         │  • agency/base-theme             │     │
│  │  • dist/archives.zip  │         │  • agency/utilities-plugin       │     │
│  │  • index.html         │         │  • agency/client-a-theme         │     │
│  │  • Auto-rebuild cron  │         │  • agency/client-b-theme         │     │
│  └───────────┬───────────┘         └──────────────────────────────────┘     │
│              │                                                               │
│              │ HTTPS (with HTTP Basic Auth)                                 │
│              │ composer install/update                                      │
│              │                                                               │
│              ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    Bedrock WordPress Sites                           │    │
│  ├───────────────────┬───────────────────┬─────────────────────────────┤    │
│  │  Client A         │  Client B         │  Client C                   │    │
│  │  ┌─────────────┐  │  ┌─────────────┐  │  ┌─────────────┐            │    │
│  │  │ Development │  │  │ Development │  │  │ Development │            │    │
│  │  └─────────────┘  │  └─────────────┘  │  └─────────────┘            │    │
│  │  ┌─────────────┐  │  ┌─────────────┐  │  ┌─────────────┐            │    │
│  │  │ Staging     │  │  │ Staging     │  │  │ Staging     │            │    │
│  │  └─────────────┘  │  └─────────────┘  │  └─────────────┘            │    │
│  │  ┌─────────────┐  │  ┌─────────────┐  │  ┌─────────────┐            │    │
│  │  │ Production  │  │  │ Production  │  │  │ Production  │            │    │
│  │  └─────────────┘  │  └─────────────┘  │  └─────────────┘            │    │
│  │                   │                   │                             │    │
│  │  Shared:          │  Shared:          │  Shared:                    │    │
│  │  • base-theme     │  • base-theme     │  • base-theme               │    │
│  │  • utilities      │  • utilities      │  • utilities                │    │
│  │                   │                   │                             │    │
│  │  Custom:          │  Custom:          │  Custom:                    │    │
│  │  • client-a-theme │  • client-b-theme │  • client-c-theme           │    │
│  └───────────────────┴───────────────────┴─────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Interaction Flow

### 1. Package Release Flow

```
Developer                   Git Repository              Satis Server           Bedrock Site
    │                            │                           │                      │
    │ 1. git commit/push         │                           │                      │
    ├──────────────────────────►│                           │                      │
    │                            │                           │                      │
    │ 2. git tag v1.1.0          │                           │                      │
    ├──────────────────────────►│                           │                      │
    │                            │                           │                      │
    │                            │ 3. Webhook trigger        │                      │
    │                            ├─────────────────────────►│                      │
    │                            │                           │                      │
    │                            │ 4. Clone repo, scan tags  │                      │
    │                            │◄──────────────────────────┤                      │
    │                            │                           │                      │
    │                            │                           │ 5. Generate archives │
    │                            │                           │ & packages.json      │
    │                            │                           │                      │
    │                            │                           │ 6. composer update   │
    │                            │                           │◄─────────────────────┤
    │                            │                           │                      │
    │                            │                           │ 7. Download ZIP      │
    │                            │                           ├─────────────────────►│
    │                            │                           │                      │
    │                            │                           │                      │
```

### 2. Build Process (Satis)

**Triggered by:**
- Webhook from git push/tag (immediate)
- Cron job (periodic, e.g., every 6 hours)
- Manual rebuild command

**Steps:**
1. **Repository Scanning** - Clone/update all configured VCS repositories
2. **Package Detection** - Find all composer.json files, detect tags/branches
3. **Dependency Resolution** - If `require-dependencies: true`, resolve transitive deps
4. **Archive Generation** - Create ZIP/TAR archives if `archive` configured
5. **Metadata Generation** - Build `packages.json` with all package versions
6. **HTML Generation** - Render web interface if `output-html: true`

**Output:**
```
output/
├── index.html              # Browsable package catalog
├── packages.json           # Main Composer metadata
├── include/                # Split metadata (if providers: true)
│   └── all$<hash>.json
├── dist/                   # Package archives
│   ├── agency-base-theme-1.0.0.zip
│   ├── agency-base-theme-1.1.0.zip
│   └── agency-utilities-1.0.0.zip
└── p2/                     # Composer v2 metadata URLs
    └── agency/
        ├── base-theme.json
        └── utilities.json
```

## Data Flow

### Composer Install/Update Flow

```
Bedrock Site
    │
    │ 1. composer update agency/base-theme
    │
    ▼
┌─────────────────────────────────────────┐
│ Read composer.json repositories         │
│ → https://packages.youragency.com       │
└─────────────────────────────────────────┘
    │
    │ 2. HTTP GET /packages.json (with Basic Auth)
    │
    ▼
┌─────────────────────────────────────────┐
│ Satis Server Returns:                   │
│ {                                       │
│   "packages": {                         │
│     "agency/base-theme": {              │
│       "1.0.0": {...},                   │
│       "1.1.0": {                        │
│         "dist": {                       │
│           "type": "zip",                │
│           "url": ".../dist/agency-...", │
│         }                               │
│       }                                 │
│     }                                   │
│   }                                     │
│ }                                       │
└─────────────────────────────────────────┘
    │
    │ 3. Resolve version constraint ^1.0 → 1.1.0
    │
    ▼
┌─────────────────────────────────────────┐
│ Download ZIP archive                    │
│ → /dist/agency-base-theme-1.1.0.zip     │
└─────────────────────────────────────────┘
    │
    │ 4. Extract to web/app/themes/
    │
    ▼
┌─────────────────────────────────────────┐
│ Update composer.lock with new version   │
└─────────────────────────────────────────┘
```

## Network Architecture

### Production Setup (Recommended)

```
Internet
    │
    │ HTTPS (SSL/TLS)
    ▼
┌─────────────────────┐
│ Reverse Proxy       │
│ (Coolify/Nginx)     │
│                     │
│ • SSL termination   │
│ • HTTP Basic Auth   │
│ • Rate limiting     │
└──────────┬──────────┘
           │
           │ HTTP (internal)
           ▼
┌─────────────────────┐
│ Satis Container     │
│ (rebelinblue/satis) │
│                     │
│ • Serve packages    │
│ • Auto-rebuild      │
└─────────────────────┘
```

### Development/Testing Setup (Simplified)

```
┌─────────────────────┐
│ Satis Container     │
│ Port 80 exposed     │
│                     │
│ • No SSL            │
│ • No auth           │
│ • Local access only │
└─────────────────────┘
```

## Security Layers

```
┌────────────────────────────────────────────────────────────┐
│ Layer 1: Network                                           │
│ • IP whitelisting (optional)                               │
│ • VPN access (optional)                                    │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│ Layer 2: SSL/TLS                                           │
│ • HTTPS encryption                                         │
│ • Certificate validation                                   │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│ Layer 3: Authentication                                    │
│ • HTTP Basic Auth                                          │
│ • Credentials in auth.json (not committed to git)          │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│ Layer 4: Repository Access                                 │
│ • SSH deploy keys (read-only) for private git repos       │
│ • Per-repo access control                                 │
└────────────────────────────────────────────────────────────┘
```

## Scalability Considerations

### Small Setup (1-10 sites)
- Single Satis instance
- Cron rebuild every 6 hours
- Shared base theme + few custom themes
- **Estimated Load:** Low, <100MB packages total

### Medium Setup (10-50 sites)
- Single Satis instance with archive generation
- CDN for dist archives (optional)
- Webhook-based rebuilds for immediate updates
- **Estimated Load:** Medium, 100MB-1GB packages

### Large Setup (50+ sites)
- Multiple Satis instances (per region or client group)
- CDN mandatory for dist archives
- Separate Satis for stable vs development packages
- Cache layer (Varnish/CloudFlare) for packages.json
- **Estimated Load:** High, 1GB+ packages

## Deployment Topology Options

### Option A: Single Satis for All Sites (Simplest)

**Pros:**
- Centralized package management
- Single point of update
- Simple authentication

**Cons:**
- Single point of failure
- All sites see all packages

### Option B: Satis Per Client Group

**Pros:**
- Isolation between client groups
- Different auth per group
- Independent rebuild schedules

**Cons:**
- Multiple Satis instances to maintain
- Package duplication

### Option C: Hierarchical (Public + Private)

```
┌──────────────────────────┐
│ Public Satis             │
│ (shared themes/plugins)  │
│ • agency/base-theme      │
│ • agency/utilities       │
└────────────┬─────────────┘
             │
             │ All sites reference this
             │
             ▼
┌──────────────────────────┐
│ Client-Specific Satis    │
│ • client-a/custom-theme  │
│ • client-a/internal-tool │
└──────────────────────────┘
```

**Pros:**
- Clear separation of shared vs. custom code
- Granular access control
- Can deprecate client packages independently

**Cons:**
- Two repositories per site composer.json
- More complex setup

## Performance Characteristics

**Build Times:**
- Small repo (1-5 packages): 10-30 seconds
- Medium repo (5-20 packages): 30-120 seconds
- Large repo (20+ packages): 2-5 minutes

**Archive Generation Impact:**
- Adds 30-50% to build time
- Reduces client install time by 80%+ (no git clone)

**Composer Install Times:**
- With archives: 5-15 seconds per package
- Without archives (git clone): 30-60 seconds per package

## See Also

- [Satis Deployment Guide](../setup/satis-deployment.md) - Deploy this architecture
- [Authentication Setup](authentication.md) - Configure security layers
