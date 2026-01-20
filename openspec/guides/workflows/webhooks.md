# Webhook Configuration

Automated Satis rebuilds triggered by git push events.

## Overview

Webhooks enable automatic Satis rebuilds when you push code or create tags, eliminating manual rebuild commands.

**Flow:**
```
Developer → git push → GitHub/GitLab
                           ↓ webhook
Satis Server ← HTTP POST ← GitHub/GitLab
     ↓
Rebuild packages.json
```

## rebelinblue/satis Webhook Support

The `rebelinblue/satis` Docker image includes built-in webhook support.

### Configuration

**docker-compose.yml:**
```yaml
services:
  satis:
    image: rebelinblue/satis:latest
    environment:
      - WEBHOOK_SECRET=your-random-secret-here
    ports:
      - "80:80"
```

**Generate secret:**
```bash
openssl rand -hex 32
# Example: a3c8f9e2d1b4a5c6e7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0
```

### Webhook URL

```
https://packages.youragency.com/webhook?secret=your-random-secret-here
```

**⚠️ Important:** Keep secret confidential! Anyone with the secret can trigger rebuilds.

## GitHub Webhook Setup

### Step 1: Add Webhook

1. Go to repository: `https://github.com/agency/base-theme`
2. Settings → Webhooks → Add webhook
3. **Payload URL:** `https://packages.youragency.com/webhook?secret=YOUR_SECRET`
4. **Content type:** `application/json`
5. **Secret:** Leave empty (secret is in URL query param)
6. **Which events?** Select:
   - ☑ Just the push event
   - Or: ☑ Let me select individual events:
     - ☑ Pushes
     - ☑ Branch or tag creation
7. **Active:** ✓
8. Click "Add webhook"

### Step 2: Test Webhook

**Trigger test event:**
1. GitHub → Settings → Webhooks → Your webhook
2. Recent Deliveries → Redeliver
3. Check response:
   - ✅ 200: Success
   - ❌ 401/403: Invalid secret
   - ❌ 500: Satis error

**Manual test:**
```bash
curl -X POST "https://packages.youragency.com/webhook?secret=YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{
    "repository": {
      "clone_url": "https://github.com/agency/base-theme.git"
    }
  }'
```

### Step 3: Verify Rebuild

**Check Satis logs:**
```bash
docker logs -f satis
```

**Expected output:**
```
[2024-01-15 10:30:15] Webhook received
[2024-01-15 10:30:15] Building repository from https://github.com/agency/base-theme.git
[2024-01-15 10:30:45] Build completed successfully
```

## GitLab Webhook Setup

### Step 1: Add Webhook

1. Go to repository: `https://gitlab.com/agency/base-theme`
2. Settings → Webhooks
3. **URL:** `https://packages.youragency.com/webhook?secret=YOUR_SECRET`
4. **Secret token:** (leave empty, secret in URL)
5. **Trigger:** Select:
   - ☑ Push events
   - ☑ Tag push events
6. **SSL verification:** ✓ Enable (for HTTPS)
7. Click "Add webhook"

### Step 2: Test Webhook

**Test event:**
1. GitLab → Settings → Webhooks → Your webhook
2. Test → Push events
3. View details:
   - ✅ 200: Success
   - Hook executed successfully

**Manual test:**
```bash
curl -X POST "https://packages.youragency.com/webhook?secret=YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -H "X-Gitlab-Event: Push Hook" \
  -d '{
    "project": {
      "http_url": "https://gitlab.com/agency/base-theme.git"
    }
  }'
```

## Webhook Event Filtering

### Trigger on Specific Branches

**GitHub Actions (alternative):**

If `rebelinblue/satis` doesn't support branch filtering, use GitHub Actions:

**.github/workflows/satis-rebuild.yml:**
```yaml
name: Trigger Satis Rebuild

on:
  push:
    branches:
      - main
      - develop
    tags:
      - 'v*'

jobs:
  rebuild:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Satis Webhook
        run: |
          curl -X POST "${{ secrets.SATIS_WEBHOOK_URL }}?secret=${{ secrets.SATIS_WEBHOOK_SECRET }}"
```

**GitHub Secrets:**
- `SATIS_WEBHOOK_URL`: `https://packages.youragency.com/webhook`
- `SATIS_WEBHOOK_SECRET`: Your webhook secret

### Trigger on Specific Tags Only

**.github/workflows/satis-rebuild.yml:**
```yaml
name: Trigger Satis on Release

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'  # Only semantic version tags

jobs:
  rebuild:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Satis
        run: |
          curl -X POST "https://packages.youragency.com/webhook?secret=${{ secrets.SATIS_SECRET }}"
```

## Webhook Security

### Validate Secret

**Nginx (if custom webhook endpoint):**

```nginx
location /webhook {
    # Check query parameter
    if ($arg_secret != "your-secret-here") {
        return 401 "Unauthorized";
    }

    # Proxy to webhook handler
    proxy_pass http://127.0.0.1:8080/webhook;
}
```

### IP Whitelist

**Restrict to GitHub/GitLab IPs:**

```nginx
location /webhook {
    # GitHub webhook IPs (update regularly)
    allow 192.30.252.0/22;
    allow 185.199.108.0/22;
    allow 140.82.112.0/20;
    deny all;

    # Process webhook
    proxy_pass http://127.0.0.1:8080/webhook;
}
```

**GitHub IP ranges:** https://api.github.com/meta
```bash
curl https://api.github.com/meta | jq '.hooks'
```

**GitLab IP ranges:** https://docs.gitlab.com/ee/user/gitlab_com/

### Rate Limiting

**Prevent abuse:**

```nginx
limit_req_zone $binary_remote_addr zone=webhook:10m rate=10r/m;

location /webhook {
    limit_req zone=webhook burst=5;

    proxy_pass http://127.0.0.1:8080/webhook;
}
```

Allows 10 requests/minute with burst of 5.

## Partial Rebuilds

### Rebuild Only Changed Repository

**Webhook with repository URL parameter:**

Some Satis webhook implementations support partial rebuilds:

```bash
curl -X POST "https://packages.youragency.com/webhook?secret=SECRET&repository=https://github.com/agency/base-theme.git"
```

**Satis build command triggered:**
```bash
/satis/bin/satis build --repository-url=https://github.com/agency/base-theme.git /satis/satis.json /satis/output
```

**Benefits:**
- Faster rebuilds (only scans one repo)
- Reduced server load
- Quicker package availability

### Named Repository Optimization

**satis.json:**
```json
{
  "repositories": [
    {
      "name": "agency/base-theme",
      "type": "vcs",
      "url": "https://github.com/agency/base-theme.git"
    }
  ]
}
```

**Webhook handler detects package name:**
```bash
# Rebuilds only agency/base-theme
/satis/bin/satis build /satis/satis.json /satis/output agency/base-theme
```

## Monitoring Webhooks

### Check Recent Deliveries

**GitHub:**
1. Repository → Settings → Webhooks → Your webhook
2. Recent Deliveries tab
3. View request/response for each delivery

**GitLab:**
1. Repository → Settings → Webhooks → Your webhook
2. Recent events
3. View details for each event

### Webhook Logs

**Satis container logs:**
```bash
# Real-time logs
docker logs -f satis

# Last 100 lines
docker logs --tail 100 satis

# Filter for webhook events
docker logs satis 2>&1 | grep -i webhook
```

### Failed Webhook Debugging

**GitHub shows delivery details:**
- Request headers
- Request body
- Response status code
- Response body

**Common failure reasons:**

| Status | Reason | Fix |
|--------|--------|-----|
| 401 | Invalid secret | Check URL query parameter |
| 404 | Wrong endpoint | Verify URL path |
| 500 | Satis error | Check Satis logs |
| Timeout | Slow rebuild | Increase timeout, use partial rebuilds |

## Webhook Best Practices

### ✅ DO:

- **Use HTTPS** for webhook URLs (not HTTP)
- **Generate strong secrets** (32+ random bytes)
- **Store secrets securely** (environment variables, not git)
- **Test webhooks** after setup
- **Monitor webhook logs** regularly
- **Use partial rebuilds** when possible
- **Set up webhooks** for all package repositories

### ❌ DON'T:

- **Commit secrets** to git repositories
- **Share webhook URLs** publicly
- **Skip webhook testing**
- **Ignore failed deliveries**
- **Use weak secrets** (e.g., "password")
- **Expose webhook endpoint** without authentication

## Alternative: Cron-Only Rebuilds

**If webhooks are problematic:**

**docker-compose.yml:**
```yaml
services:
  satis:
    environment:
      - CRON_SCHEDULE=0 */6 * * *  # Every 6 hours
```

**Pros:**
- Simpler setup
- No webhook security concerns
- Predictable rebuild times

**Cons:**
- Delayed package availability (up to 6 hours)
- No immediate updates
- Wastes resources (rebuilds even without changes)

## Hybrid Approach (Recommended)

**Use both webhooks and cron:**

```yaml
services:
  satis:
    environment:
      - WEBHOOK_SECRET=your-secret
      - CRON_SCHEDULE=0 0 * * *  # Daily at midnight (backup)
```

**Benefits:**
- **Webhooks:** Immediate updates for active development
- **Cron:** Catches missed webhooks, ensures daily full rebuild
- **Reliability:** System keeps working if webhooks fail

## Troubleshooting

### Webhook Received But No Rebuild

**Check:**
1. Satis container logs: `docker logs satis`
2. SSH key permissions for git clone
3. Repository URL in webhook payload
4. Satis configuration includes repository

**Debug:**
```bash
# Manually trigger rebuild
docker exec satis /satis/bin/satis build /satis/satis.json /satis/output -vvv
```

### Webhook Times Out

**Symptoms:**
- GitHub shows timeout error
- Satis starts build but webhook returns 504

**Causes:**
- Large repository clone
- Many packages to scan
- Slow server

**Solutions:**
1. **Use partial rebuilds** (repository URL parameter)
2. **Increase timeout** in reverse proxy
3. **Async webhooks** (return 200 immediately, build in background)

**Nginx timeout:**
```nginx
location /webhook {
    proxy_read_timeout 300s;  # 5 minutes
    proxy_pass http://127.0.0.1:8080/webhook;
}
```

### Multiple Webhooks Fire Simultaneously

**Scenario:** Push with multiple commits triggers multiple webhooks

**Issue:** Concurrent Satis builds conflict

**Solution:** Queue webhook requests

**Simple queue with flock:**
```bash
#!/bin/bash
# webhook-handler.sh

(
  flock -n 200 || exit 1
  /satis/bin/satis build /satis/satis.json /satis/output
) 200>/var/lock/satis-build.lock
```

## See Also

- [Satis Deployment](../setup/satis-deployment.md) - Initial webhook setup
- [Updating Packages](updating-packages.md) - Release workflow with webhooks
- [Authentication Methods](../architecture/authentication.md) - Webhook security
