# Container Registry Setup Guide

This guide explains how to set up and use the container registry integration with Gitea for building and pushing container images.

## Features

- **Build & Push**: Build container images and push them to your Gitea registry
- **Secure Authentication**: Base64-encoded tokens for secure registry access
- **Ansible Integration**: Automated deployment with podman login in playbooks
- **Token Decoding**: Tokens are decoded only before use, never stored in plain text

## Configuration

### 1. Generate Gitea Access Token

1. Log in to your Gitea instance
2. Go to **Settings** → **Applications** → **Generate New Token**
3. Select permissions: `read:packages`, `write:packages`
4. Copy the generated token

### 2. Encode Token to Base64

```bash
echo -n "your-gitea-token" | base64
```

Save the base64-encoded output.

### 3. Add Registry Configuration

Add the registry section to your `deploy.yaml`:

```yaml
registry:
  url: gitea.example.com
  username: your-username
  token_base64: eW91ci1naXRlYS10b2tlbi1oZXJl
```

**Important**: Never commit plain text tokens to version control. Use environment variables or secret management tools.

## Usage

### Build and Push Container Image

Build a container image and push it to your Gitea registry:

```bash
dart_cloud_deploy build-push \
  --config deploy.yaml \
  --image-name myapp/backend \
  --tag v1.0.0 \
  --dockerfile Dockerfile.backend \
  --context .
```

#### Options

- `--config, -c`: Configuration file path (default: `deploy.yaml`)
- `--image-name, -i`: Image name without registry URL (required)
- `--tag, -t`: Image tag (default: `latest`)
- `--dockerfile, -d`: Path to Dockerfile (default: `Dockerfile`)
- `--context`: Build context path (default: `.`)
- `--build-arg`: Build arguments (can be specified multiple times)
- `--no-push`: Build only, do not push to registry
- `--verbose, -v`: Verbose output

#### Examples

**Basic build and push:**

```bash
dart_cloud_deploy build-push -i myapp/backend -t latest
```

**Build with custom Dockerfile:**

```bash
dart_cloud_deploy build-push \
  -i myapp/backend \
  -t v1.2.3 \
  -d deployment/Dockerfile.prod \
  --context ./backend
```

**Build with build arguments:**

```bash
dart_cloud_deploy build-push \
  -i myapp/backend \
  -t latest \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

**Build only (no push):**

```bash
dart_cloud_deploy build-push -i myapp/backend -t dev --no-push
```

## Ansible Integration

The CLI includes an Ansible playbook template for deploying containers from your registry.

### Playbook Features

1. **Secure Token Handling**: Token is base64-encoded in config and decoded only in playbook
2. **Podman Login**: Automatically logs into registry using decoded token
3. **Image Pull**: Pulls the specified image from registry
4. **Container Deployment**: Stops old container, starts new one
5. **Health Check**: Waits for service to be healthy
6. **Cleanup**: Logs out from registry and prunes unused images

### Key Playbook Steps

```yaml
- name: Decode registry token
  ansible.builtin.set_fact:
    registry_token: "{{ registry_token_base64 | b64decode }}"
  no_log: true

- name: Login to container registry
  ansible.builtin.shell: |
    echo "{{ registry_token }}" | podman login {{ registry_url }} \
      --username {{ registry_username }} --password-stdin
  no_log: true
```

### Generate and Run Playbook

The playbook is generated automatically by the `PlaybookService`:

```dart
final playbookPath = await playbookService.generateContainerRegistryPlaybook(
  config,
  imageName: 'myapp/backend',
  imageTag: 'v1.0.0',
);
```

## Security Best Practices

### 1. Token Storage

- **Never** commit plain text tokens to version control
- Store base64-encoded tokens in secure configuration management
- Use environment variables for sensitive values:

```yaml
registry:
  url: gitea.example.com
  username: ${REGISTRY_USERNAME}
  token_base64: ${REGISTRY_TOKEN_BASE64}
```

### 2. Token Rotation

Regularly rotate your Gitea access tokens:

1. Generate new token in Gitea
2. Encode to base64
3. Update configuration
4. Revoke old token

### 3. Ansible Security

- Playbook uses `no_log: true` to prevent token exposure in logs
- Token is decoded in-memory only during playbook execution
- Automatic logout after deployment

### 4. File Permissions

Protect your configuration files:

```bash
chmod 600 deploy.yaml
```

## Workflow Example

### Complete CI/CD Workflow

```bash
# 1. Build and push image to registry
dart_cloud_deploy build-push \
  -i myapp/backend \
  -t $(git rev-parse --short HEAD) \
  -d Dockerfile.backend

# 2. Deploy to dev environment
dart_cloud_deploy deploy-dev \
  --config deploy.yaml \
  --target backend \
  -e image_tag=$(git rev-parse --short HEAD)
```

## Troubleshooting

### Login Failed

**Error**: `Failed to login to registry`

**Solutions**:

- Verify token is valid and not expired
- Check token has correct permissions (`read:packages`, `write:packages`)
- Ensure registry URL is correct (no `https://` prefix)
- Test manual login: `echo "token" | podman login gitea.example.com -u username --password-stdin`

### Build Failed

**Error**: `Failed to build image`

**Solutions**:

- Verify Dockerfile path is correct
- Check build context contains all required files
- Review build logs for specific errors
- Test manual build: `podman build -t test -f Dockerfile .`

### Push Failed

**Error**: `Failed to push image`

**Solutions**:

- Verify you're logged into registry
- Check network connectivity to registry
- Ensure sufficient disk space
- Verify image name format: `registry.com/namespace/image:tag`

### Base64 Decoding Failed

**Error**: `Failed to decode registry token`

**Solutions**:

- Verify token is properly base64-encoded
- Check for extra whitespace or newlines
- Re-encode token: `echo -n "token" | base64`

## Registry Configuration Examples

### Gitea

```yaml
registry:
  url: gitea.example.com
  username: myuser
  token_base64: <base64-token>
```

### GitLab Container Registry

```yaml
registry:
  url: registry.gitlab.com
  username: myuser
  token_base64: <base64-token>
```

### Harbor

```yaml
registry:
  url: harbor.example.com
  username: myuser
  token_base64: <base64-token>
```

### GitHub Container Registry

```yaml
registry:
  url: ghcr.io
  username: myuser
  token_base64: <base64-token>
```

## Additional Resources

- [Gitea Packages Documentation](https://docs.gitea.io/en-us/packages/overview/)
- [Podman Login Documentation](https://docs.podman.io/en/latest/markdown/podman-login.1.html)
- [Ansible no_log Documentation](https://docs.ansible.com/ansible/latest/reference_appendices/logging.html)
