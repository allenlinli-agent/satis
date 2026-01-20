# Authentication Methods

Security strategies for protecting your private Satis repository.

## Authentication Options

| Method | Security | Ease of Setup | Use Case |
|--------|----------|---------------|----------|
| HTTP Basic Auth | Medium | Easy | Recommended for most |
| Token-Based Auth | High | Medium | API integrations, CI/CD |
| IP Whitelist | Low | Easy | Internal networks only |
| VPN Access | High | Complex | Enterprise environments |
| SSH Keys Only | Medium | Medium | Git-only access |

## HTTP Basic Auth (Recommended)

### Server Configuration

**Nginx (in Satis container):**

Create `/etc/nginx/.htpasswd`:
```bash
htpasswd -c /etc/nginx/.htpasswd composer
# Enter password when prompted
```

**Nginx config** (`/etc/nginx/sites-available/default`):
```nginx
server {
    listen 80;
    server_name packages.youragency.com;

    root /satis/output;
    index index.html packages.json;

    auth_basic "Private Package Repository";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.json$ {
        add_header Content-Type application/json;
    }
}
```

**Docker Compose volume:**
```yaml
services:
  satis:
    volumes:
      - ./htpasswd/.htpasswd:/etc/nginx/.htpasswd:ro
```

### Client Configuration

**Method 1: auth.json (Recommended)**

Create `auth.json` in Bedrock project root:
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

**Add to .gitignore:**
```bash
echo "auth.json" >> .gitignore
```

**Method 2: Global Configuration**

```bash
composer config --global http-basic.packages.youragency.com composer password
```

Stores in `~/.composer/auth.json`.

**Method 3: Environment Variable**

```bash
export COMPOSER_AUTH='{"http-basic":{"packages.youragency.com":{"username":"composer","password":"password"}}}'

composer install
```

**Method 4: Interactive Prompt**

```bash
composer install
# Prompts: Username: composer
# Prompts: Password: ********
# Asks: Do you want to store credentials? yes
```

### Adding Multiple Users

```bash
# Add developer user
htpasswd /etc/nginx/.htpasswd developer

# Add CI/CD user
htpasswd /etc/nginx/.htpasswd ci-deploy

# List users
cat /etc/nginx/.htpasswd
# composer:$apr1$...
# developer:$apr1$...
# ci-deploy:$apr1$...
```

### Rotating Passwords

```bash
# Update password
htpasswd /etc/nginx/.htpasswd composer

# Restart Nginx
docker exec satis nginx -s reload
```

**Update clients:**
```bash
# Each Bedrock site
vim auth.json  # Update password
composer clear-cache
```

## Token-Based Authentication

### Server Configuration

**Custom Nginx config with token validation:**

```nginx
server {
    listen 80;
    server_name packages.youragency.com;

    root /satis/output;

    location / {
        # Check for Authorization header
        if ($http_authorization != "Bearer YOUR_SECRET_TOKEN") {
            return 401 "Unauthorized";
        }

        try_files $uri $uri/ =404;
    }
}
```

**Or use Lua for more complex logic:**

```nginx
location / {
    access_by_lua_block {
        local auth_header = ngx.var.http_authorization
        local valid_token = "Bearer your-secret-token-here"

        if auth_header ~= valid_token then
            ngx.status = 401
            ngx.say("Unauthorized")
            return ngx.exit(401)
        end
    }

    try_files $uri $uri/ =404;
}
```

### Client Configuration

**composer.json:**
```json
{
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com",
      "options": {
        "http": {
          "header": [
            "Authorization: Bearer YOUR_SECRET_TOKEN"
          ]
        }
      }
    }
  ]
}
```

**Environment variable approach:**
```bash
export PACKAGES_TOKEN="your-secret-token"
```

**composer.json with env var:**
```json
{
  "repositories": [
    {
      "type": "composer",
      "url": "https://packages.youragency.com",
      "options": {
        "http": {
          "header": [
            "Authorization: Bearer ${PACKAGES_TOKEN}"
          ]
        }
      }
    }
  ]
}
```

### Generating Secure Tokens

```bash
# Random 32-byte hex string
openssl rand -hex 32

# Or base64
openssl rand -base64 32
```

## IP Whitelist

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name packages.youragency.com;

    root /satis/output;

    # Allow specific IPs
    allow 192.168.1.0/24;      # Office network
    allow 203.0.113.10;         # VPS 1
    allow 203.0.113.20;         # VPS 2
    deny all;                   # Deny everyone else

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### CloudFlare Access Rules

**If using CloudFlare:**

1. CloudFlare Dashboard → Security → WAF → Tools
2. Add rule:
   ```
   Field: IP Address
   Operator: is in
   Value: 192.168.1.0/24
   Action: Allow
   ```

3. Add default rule:
   ```
   Field: All traffic
   Action: Block
   ```

**Pros:**
- No password management
- Simple for known IPs

**Cons:**
- Doesn't work with dynamic IPs (home networks, mobile)
- Difficult to manage many developers

## SSL/TLS Configuration

### Let's Encrypt with Coolify

**Coolify automatically provisions SSL:**
1. Add domain: `packages.youragency.com`
2. Enable SSL: ✓
3. Coolify handles certificate renewal

**Manual Nginx config (if needed):**
```nginx
server {
    listen 443 ssl http2;
    server_name packages.youragency.com;

    ssl_certificate /etc/letsencrypt/live/packages.youragency.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/packages.youragency.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /satis/output;

    auth_basic "Private Packages";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files $uri $uri/ =404;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name packages.youragency.com;
    return 301 https://$server_name$request_uri;
}
```

### Self-Signed Certificate (Development)

```bash
# Generate self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/packages.key \
  -out /etc/nginx/ssl/packages.crt

# Use in Nginx
ssl_certificate /etc/nginx/ssl/packages.crt;
ssl_certificate_key /etc/nginx/ssl/packages.key;
```

**Client configuration** (ignore SSL verification - development only):
```json
{
  "config": {
    "secure-http": false
  }
}
```

**⚠️ Never use in production!**

## VPN Access

### WireGuard VPN Setup

**Server:**
```bash
# Install WireGuard
apt install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Configure /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <server-private-key>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32

# Start VPN
wg-quick up wg0
```

**Client:**
```bash
# Generate client keys
wg genkey | tee client-privatekey | wg pubkey > client-publickey

# Configure /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/24

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn.youragency.com:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25

# Connect
wg-quick up wg0
```

**Nginx config** (only listen on VPN interface):
```nginx
server {
    listen 10.0.0.1:80;  # VPN IP only
    server_name packages.youragency.internal;

    # No authentication needed (VPN provides auth)
    root /satis/output;
}
```

## Layered Security (Recommended)

### Multi-Layer Approach

```
┌─────────────────────────────────────────────┐
│ Layer 1: Network (VPN or IP Whitelist)     │
│ ↓ Optional but recommended                 │
└─────────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ Layer 2: SSL/TLS (HTTPS)                   │
│ ↓ Required                                  │
└─────────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ Layer 3: Authentication                     │
│ ↓ HTTP Basic Auth or Token                 │
└─────────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ Layer 4: Repository Access                 │
│ ↓ SSH keys for git repos                   │
└─────────────────────────────────────────────┘
```

**Example configuration:**
1. **VPN:** Only accessible from office or VPN clients
2. **HTTPS:** All traffic encrypted
3. **HTTP Basic Auth:** Per-user authentication
4. **SSH Keys:** Read-only deploy keys for git repos

## Security Best Practices

### Password Policies

**✅ DO:**
- Use unique passwords per service
- Minimum 16 characters for HTTP Basic Auth
- Use password manager (1Password, Bitwarden)
- Rotate passwords every 90 days
- Different passwords for dev/staging/production

**❌ DON'T:**
- Hardcode passwords in repositories
- Share passwords via email/Slack
- Reuse passwords across services
- Use weak passwords (e.g., "password123")

### Token Management

**✅ DO:**
- Generate random tokens (32+ bytes)
- Store tokens in environment variables
- Use separate tokens per environment
- Revoke tokens when team members leave
- Log token usage (failed auth attempts)

**❌ DON'T:**
- Commit tokens to git
- Share tokens in plain text
- Use predictable tokens
- Reuse tokens across projects

### Access Control

**✅ DO:**
- Follow principle of least privilege
- Use read-only SSH keys for Satis
- Audit access logs regularly
- Remove access for departed team members
- Use separate credentials for CI/CD

**❌ DON'T:**
- Use shared credentials
- Grant write access when read is sufficient
- Skip access audits
- Leave old credentials active

## Monitoring and Logging

### Nginx Access Logs

**Enable logging:**
```nginx
access_log /var/log/nginx/packages-access.log combined;
error_log /var/log/nginx/packages-error.log;
```

**Monitor for suspicious activity:**
```bash
# Failed auth attempts
grep "401" /var/log/nginx/packages-access.log

# Unusual IPs
awk '{print $1}' /var/log/nginx/packages-access.log | sort | uniq -c | sort -rn

# Download frequency
grep "dist/" /var/log/nginx/packages-access.log | wc -l
```

### Fail2Ban Integration

**Protect against brute force:**

```ini
# /etc/fail2ban/filter.d/nginx-satis.conf
[Definition]
failregex = ^<HOST> .* "GET .* HTTP/.*" 401

# /etc/fail2ban/jail.local
[nginx-satis]
enabled = true
filter = nginx-satis
logpath = /var/log/nginx/packages-access.log
maxretry = 3
bantime = 3600
```

## See Also

- [Satis Deployment](../setup/satis-deployment.md) - Setup authentication
- [Bedrock Configuration](../setup/bedrock-configuration.md) - Client auth config
- [Architecture Overview](overview.md) - Security layers
