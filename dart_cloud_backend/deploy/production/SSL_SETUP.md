# SSL/TLS Setup for Production PostgreSQL

Complete guide for setting up secure PostgreSQL connections with SSL/TLS certificates for production deployments.

## Overview

This setup provides:
- **End-to-end encryption** for PostgreSQL connections
- **Certificate-based authentication** (mutual TLS)
- **Self-signed CA** for internal infrastructure
- **Separate certificates** for server (PostgreSQL) and client (Backend)
- **Production-ready configuration** with security best practices

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Production Environment                    │
│                                                              │
│  ┌──────────────────┐                 ┌──────────────────┐ │
│  │     Backend      │    SSL/TLS      │   PostgreSQL     │ │
│  │                  │◀───────────────▶│                  │ │
│  │  Client Cert:    │   Encrypted     │  Server Cert:    │ │
│  │  - client.crt    │   Connection    │  - server.crt    │ │
│  │  - client.key    │                 │  - server.key    │ │
│  │  - root.crt      │                 │  - root.crt      │ │
│  └──────────────────┘                 └──────────────────┘ │
│           │                                     │           │
│           └─────────────┬───────────────────────┘           │
│                         │                                   │
│                    ┌────▼────┐                              │
│                    │   CA    │                              │
│                    │  Cert   │                              │
│                    │ ca.crt  │                              │
│                    └─────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Generate SSL Certificates

```bash
cd dart_cloud_backend/deploy
chmod +x generate-ssl-certs.sh
./generate-ssl-certs.sh
```

This creates:
- Certificate Authority (CA)
- Server certificates (PostgreSQL)
- Client certificates (Backend)

### 2. Setup Production Environment

```bash
# Copy production environment template
cp .env.production.example .env.production

# Generate secure passwords
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 64  # For JWT_SECRET

# Edit .env.production
nano .env.production

# Secure the file
chmod 600 .env.production
```

### 3. Deploy to Production

```bash
chmod +x deploy-production.sh
./deploy-production.sh
```

The script automatically:
- Validates SSL certificates
- Checks environment variables
- Verifies configuration
- Deploys with SSL enabled
- Tests SSL connection

## Files Created

### SSL Certificates (`ssl/` directory)

| File | Type | Description | Permissions |
|------|------|-------------|-------------|
| `ca-key.pem` | Private Key | CA private key | 600 (keep secure!) |
| `ca-cert.pem` | Certificate | CA certificate | 644 (public) |
| `server-key.pem` | Private Key | PostgreSQL private key | 600 (keep secure!) |
| `server-cert.pem` | Certificate | PostgreSQL certificate | 644 (public) |
| `client-key.pem` | Private Key | Backend private key | 600 (keep secure!) |
| `client-cert.pem` | Certificate | Backend certificate | 644 (public) |

### Configuration Files

| File | Description |
|------|-------------|
| `generate-ssl-certs.sh` | Certificate generation script |
| `docker-compose.prod.yml` | Production Docker Compose with SSL |
| `.env.production.example` | Production environment template |
| `postgresql.conf` | PostgreSQL production configuration |
| `deploy-production.sh` | Production deployment script |
| `SSL_SETUP.md` | This documentation |

## Certificate Generation Options

### Basic Generation

```bash
./generate-ssl-certs.sh
```

### Custom Configuration

```bash
./generate-ssl-certs.sh \
  --days 365 \
  --country US \
  --state California \
  --city "San Francisco" \
  --org "My Company" \
  --cn "postgres.example.com"
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--days` | 3650 | Certificate validity (days) |
| `--country` | US | Country code |
| `--state` | State | State/Province |
| `--city` | City | City |
| `--org` | ContainerPub | Organization name |
| `--cn` | postgres | Common Name (hostname) |

## SSL Configuration

### PostgreSQL SSL Settings

In `docker-compose.prod.yml`:

```yaml
postgres:
  volumes:
    - ./ssl/server-cert.pem:/var/lib/postgresql/server.crt:ro
    - ./ssl/server-key.pem:/var/lib/postgresql/server.key:ro
    - ./ssl/ca-cert.pem:/var/lib/postgresql/root.crt:ro
  command: >
    postgres
    -c ssl=on
    -c ssl_cert_file=/var/lib/postgresql/server.crt
    -c ssl_key_file=/var/lib/postgresql/server.key
    -c ssl_ca_file=/var/lib/postgresql/root.crt
    -c ssl_min_protocol_version=TLSv1.2
```

### Backend SSL Configuration

Connection string with SSL parameters:

```bash
DATABASE_URL="postgres://user:pass@postgres:5432/db?sslmode=verify-ca&sslcert=/app/ssl/client.crt&sslkey=/app/ssl/client.key&sslrootcert=/app/ssl/root.crt"
```

### SSL Modes

| Mode | Description | Security Level |
|------|-------------|----------------|
| `disable` | No SSL | ❌ Not secure |
| `require` | SSL required, no verification | ⚠️ Basic |
| `verify-ca` | SSL + CA verification | ✅ Recommended |
| `verify-full` | SSL + CA + hostname verification | ✅✅ Most secure |

**Production recommendation:** Use `verify-ca` or `verify-full`

## Security Best Practices

### 1. Certificate Management

✅ **Do:**
- Generate strong certificates (4096-bit RSA)
- Use unique certificates per environment
- Set proper file permissions (600 for keys)
- Store CA key securely offline
- Rotate certificates before expiry
- Use certificate monitoring

❌ **Don't:**
- Commit certificates to version control
- Share private keys
- Use same certificates across environments
- Use weak encryption
- Ignore expiry warnings

### 2. File Permissions

```bash
# Set secure permissions
chmod 600 ssl/ca-key.pem
chmod 600 ssl/server-key.pem
chmod 600 ssl/client-key.pem
chmod 644 ssl/*.crt
chmod 644 ssl/*-cert.pem

# Verify permissions
ls -la ssl/
```

### 3. Environment Variables

```bash
# Secure .env.production
chmod 600 .env.production

# Verify it's in .gitignore
git check-ignore .env.production

# Never log sensitive data
grep -r "POSTGRES_PASSWORD" logs/  # Should return nothing
```

### 4. Network Security

- Don't expose PostgreSQL port publicly
- Use firewall rules
- Implement VPN for remote access
- Enable connection logging
- Monitor failed authentication attempts

## Verification

### Verify Certificate Generation

```bash
# Check certificates exist
ls -la ssl/

# Verify server certificate
openssl verify -CAfile ssl/ca-cert.pem ssl/server-cert.pem

# Verify client certificate
openssl verify -CAfile ssl/ca-cert.pem ssl/client-cert.pem

# Check certificate details
openssl x509 -in ssl/server-cert.pem -text -noout

# Check expiry date
openssl x509 -in ssl/server-cert.pem -noout -enddate
```

### Test SSL Connection

```bash
# From host machine
psql "sslmode=require host=localhost port=5432 user=dart_cloud dbname=dart_cloud"

# From Docker container
docker compose -f docker-compose.prod.yml exec postgres \
  psql "sslmode=require host=localhost user=dart_cloud dbname=dart_cloud"

# Verify SSL is active
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U dart_cloud -d dart_cloud -c "SELECT * FROM pg_stat_ssl;"
```

### Check SSL Status

```bash
# View PostgreSQL SSL settings
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U dart_cloud -d dart_cloud -c "SHOW ssl;"

# Check active SSL connections
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U dart_cloud -d dart_cloud -c "SELECT datname, usename, ssl, client_addr FROM pg_stat_ssl JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid;"
```

## Troubleshooting

### Certificate Verification Failed

**Problem:** `SSL error: certificate verify failed`

**Solutions:**
```bash
# Regenerate certificates
./generate-ssl-certs.sh

# Check certificate validity
openssl verify -CAfile ssl/ca-cert.pem ssl/server-cert.pem

# Verify file permissions
ls -la ssl/

# Check certificate dates
openssl x509 -in ssl/server-cert.pem -noout -dates
```

### Permission Denied

**Problem:** `could not access private key file: Permission denied`

**Solutions:**
```bash
# Fix permissions
chmod 600 ssl/*-key.pem
chmod 644 ssl/*.crt ssl/*-cert.pem

# Check ownership (should be readable by postgres user)
docker compose -f docker-compose.prod.yml exec postgres ls -la /var/lib/postgresql/
```

### SSL Connection Refused

**Problem:** `SSL connection has been closed unexpectedly`

**Solutions:**
```bash
# Check PostgreSQL logs
docker compose -f docker-compose.prod.yml logs postgres

# Verify SSL is enabled
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U dart_cloud -d dart_cloud -c "SHOW ssl;"

# Test without SSL first
psql "sslmode=disable host=localhost port=5432 user=dart_cloud dbname=dart_cloud"

# Then test with SSL
psql "sslmode=require host=localhost port=5432 user=dart_cloud dbname=dart_cloud"
```

### Certificate Expired

**Problem:** `certificate has expired`

**Solutions:**
```bash
# Check expiry
openssl x509 -in ssl/server-cert.pem -noout -enddate

# Regenerate certificates
./generate-ssl-certs.sh --days 3650

# Restart services
docker compose -f docker-compose.prod.yml restart
```

## Certificate Rotation

### When to Rotate

- **Before expiry** (at least 30 days before)
- **After security incident**
- **Regular schedule** (annually recommended)
- **When private key is compromised**

### Rotation Process

```bash
# 1. Backup current certificates
cp -r ssl ssl_backup_$(date +%Y%m%d)

# 2. Generate new certificates
./generate-ssl-certs.sh

# 3. Test configuration
docker compose -f docker-compose.prod.yml config

# 4. Deploy with zero downtime
docker compose -f docker-compose.prod.yml up -d --no-deps postgres
docker compose -f docker-compose.prod.yml up -d --no-deps backend

# 5. Verify SSL connection
docker compose -f docker-compose.prod.yml exec postgres \
  psql "sslmode=require host=localhost user=dart_cloud dbname=dart_cloud" \
  -c "SELECT version();"

# 6. Remove old certificates (after verification)
rm -rf ssl_backup_*
```

## Monitoring

### Certificate Expiry Monitoring

```bash
#!/bin/bash
# check-cert-expiry.sh

CERT_FILE="ssl/server-cert.pem"
EXPIRY_DATE=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt 30 ]; then
    echo "WARNING: Certificate expires in $DAYS_LEFT days!"
    # Send alert
elif [ $DAYS_LEFT -lt 90 ]; then
    echo "NOTICE: Certificate expires in $DAYS_LEFT days"
else
    echo "OK: Certificate valid for $DAYS_LEFT days"
fi
```

### SSL Connection Monitoring

```sql
-- Monitor SSL connections
SELECT 
    datname,
    usename,
    application_name,
    client_addr,
    ssl,
    version AS ssl_version,
    cipher AS ssl_cipher
FROM pg_stat_ssl
JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
WHERE ssl = true;
```

## Production Checklist

Before deploying to production:

- [ ] SSL certificates generated
- [ ] Certificates verified and valid
- [ ] File permissions set correctly (600 for keys)
- [ ] `.env.production` created with secure values
- [ ] `.env.production` has 600 permissions
- [ ] SSL certificates NOT in version control
- [ ] `.gitignore` includes ssl/ directory
- [ ] PostgreSQL SSL configuration tested
- [ ] Backend SSL connection tested
- [ ] Certificate expiry monitoring set up
- [ ] Backup procedures documented
- [ ] Certificate rotation schedule planned
- [ ] Security audit completed
- [ ] Firewall rules configured
- [ ] Monitoring and alerting enabled

## Additional Security

### 1. Certificate Pinning

For extra security, pin the CA certificate in your application:

```dart
// Example in Dart
final securityContext = SecurityContext()
  ..setTrustedCertificatesBytes(File('/app/ssl/root.crt').readAsBytesSync());
```

### 2. Mutual TLS (mTLS)

Already configured! Both server and client authenticate each other.

### 3. Certificate Revocation

For production, consider implementing:
- Certificate Revocation Lists (CRL)
- Online Certificate Status Protocol (OCSP)

### 4. Hardware Security Modules (HSM)

For enterprise deployments:
- Store CA private key in HSM
- Use HSM for certificate signing
- Implement key ceremony procedures

## References

- [PostgreSQL SSL Documentation](https://www.postgresql.org/docs/current/ssl-tcp.html)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP TLS Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html)

## Support

For issues with SSL setup:
1. Check certificate validity: `openssl verify -CAfile ssl/ca-cert.pem ssl/server-cert.pem`
2. Review PostgreSQL logs: `docker compose -f docker-compose.prod.yml logs postgres`
3. Test connection: `psql "sslmode=require host=localhost ..."`
4. Verify file permissions: `ls -la ssl/`
5. Check configuration: `docker compose -f docker-compose.prod.yml config`

---

**Remember:** SSL/TLS is just one layer of security. Implement defense in depth with firewalls, monitoring, access controls, and regular security audits.
