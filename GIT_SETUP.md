# Git Configuration for Private Repositories

This guide explains how to configure the Multica daemon container to clone private repositories using either SSH keys or HTTPS with Personal Access Tokens (PAT).

## Choose Your Authentication Method

You can use **one** of the following methods:

1. **SSH Keys** - Traditional method, secure, requires SSH key management
2. **HTTPS with PAT** - Simpler setup, works better through firewalls, easier credential rotation

## Method 1: SSH Key Authentication

### Prerequisites

- An SSH key pair for accessing your git repositories
- The private key should be available on your host machine (typically at `~/.ssh/id_rsa`)

### Configuration

### 1. Set Environment Variables

Create or update your `.env` file in the project root with the following variables:

```bash
# Git SSH key path (defaults to ~/.ssh/id_rsa if not set)
SSH_PRIVATE_KEY_PATH=~/.ssh/id_rsa

# Optional: Git user configuration
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"

# Optional: SSH config and known_hosts
# SSH_CONFIG_PATH=~/.ssh/config
# SSH_KNOWN_HOSTS_PATH=~/.ssh/known_hosts
```

### 2. SSH Key Setup

The container will automatically:
- Mount your SSH private key (read-only)
- Set correct permissions (600) on the private key
- Add common git hosts (GitHub, GitLab, BitBucket) to known_hosts
- Configure git with your user name and email if provided

### 3. Using Different SSH Keys

If you use different SSH keys for different git hosts, you have two options:

#### Option A: Mount SSH Config File

Uncomment the SSH config volume mount in `docker-compose.yml`:

```yaml
- ${SSH_CONFIG_PATH:-~/.ssh/config}:/home/multica/.ssh/config:ro
```

Then create or update your `~/.ssh/config`:

```
Host github.com
    IdentityFile ~/.ssh/id_rsa_github
    
Host gitlab.company.com
    IdentityFile ~/.ssh/id_rsa_gitlab
```

#### Option B: Specify Different Key Path

Set the `SSH_PRIVATE_KEY_PATH` to point to your specific key:

```bash
SSH_PRIVATE_KEY_PATH=~/.ssh/id_rsa_company
```

### 4. Custom Git Hosts

If you're using a self-hosted git server, you may need to add it to known_hosts. Uncomment the known_hosts volume in `docker-compose.yml`:

```yaml
- ${SSH_KNOWN_HOSTS_PATH:-~/.ssh/known_hosts}:/home/multica/.ssh/known_hosts:ro
```

Or add the host to your local `~/.ssh/known_hosts` first:

```bash
ssh-keyscan -t rsa git.yourcompany.com >> ~/.ssh/known_hosts
```

## Method 2: HTTPS with Personal Access Token (PAT)

### Prerequisites

- A Personal Access Token (PAT) from your git provider:
  - **GitHub**: Settings → Developer settings → Personal access tokens → Generate new token
  - **GitLab**: User Settings → Access Tokens → Add new token
  - **Bitbucket**: Personal settings → App passwords → Create app password

### Configuration

### 1. Set Environment Variables

Create or update your `.env` file in the project root:

```bash
# HTTPS authentication with Personal Access Token
GIT_USERNAME=your-git-username
GIT_TOKEN=ghp_your_personal_access_token_here

# Git user configuration (optional, but recommended for commits)
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"

# Credential helper (optional, default is "store")
# Options: store (persistent), cache (temporary), or empty to disable
GIT_CREDENTIAL_HELPER=store
```

### 2. Token Setup

The container will automatically:
- Configure git credential helper (store/cache)
- Create `.git-credentials` file with your token
- Set up authentication for GitHub, GitLab, and Bitbucket
- Configure git with your user name and email if provided

### 3. Creating Personal Access Tokens

#### GitHub
1. Go to Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token"
3. Select scopes: `repo` (full control of private repositories)
4. Copy the token (you won't see it again!)

#### GitLab
1. Go to User Settings → Access Tokens
2. Create a token with `read_repository` and `write_repository` scopes
3. Copy the token

#### Bitbucket
1. Go to Personal settings → App passwords
2. Create an app password with Repository read/write permissions
3. Copy the password

### 4. Using Custom Git Hosts

For self-hosted git servers, the credentials file will need manual editing. You can extend the startup script or manually add credentials:

```bash
# Add to .git-credentials file
https://username:token@git.yourcompany.com
```

### Advantages of HTTPS/PAT

- ✅ No SSH key file management
- ✅ Works through corporate firewalls
- ✅ Easy to rotate/revoke tokens
- ✅ Can scope permissions per token
- ✅ Simpler for CI/CD environments

### Disadvantages of HTTPS/PAT

- ❌ Token visible in process list during git operations
- ❌ Need to manage token expiration
- ❌ Stored in plaintext in `.git-credentials` (with file permissions 600)

## Testing

After starting the container, you can test git access:

```bash
# Check if git is installed
docker exec multica-daemon git --version

# Check git configuration
docker exec multica-daemon git config --list

# For SSH: Test SSH connection to GitHub
docker exec multica-daemon ssh -T git@github.com

# For HTTPS: Test cloning with HTTPS URL
docker exec multica-daemon git clone https://github.com/your-org/your-private-repo.git /tmp/test

# For SSH: Test cloning with SSH URL
docker exec multica-daemon git clone git@github.com:your-org/your-private-repo.git /tmp/test
```

## Troubleshooting

### SSH Method Issues

#### Permission Denied (publickey)

If you get this error, check:
1. The SSH key path is correct in your `.env` file
2. The public key is added to your git provider (GitHub/GitLab/etc.)
3. The private key has the correct permissions (container sets this automatically)
4. Test SSH connection: `docker exec multica-daemon ssh -T git@github.com`

#### Host Key Verification Failed

This means the git host is not in known_hosts. Solutions:
- Mount your existing known_hosts file (see Configuration section)
- Let the container add common hosts automatically (default behavior)
- Manually add the host: `ssh-keyscan -t rsa your-git-host.com >> ~/.ssh/known_hosts`

### HTTPS Method Issues

#### Authentication Failed

If you get authentication errors with HTTPS:
1. Verify `GIT_USERNAME` and `GIT_TOKEN` are set correctly in `.env`
2. Check that the token has the required permissions (repo access)
3. Ensure the token hasn't expired
4. Test manually: `docker exec multica-daemon git ls-remote https://github.com/your-org/repo.git`

#### Token Not Working

If git still prompts for credentials:
1. Check credential helper is configured: `docker exec multica-daemon git config --global credential.helper`
2. Verify `.git-credentials` file exists: `docker exec multica-daemon cat ~/.git-credentials`
3. Check file permissions: `docker exec multica-daemon ls -la ~/.git-credentials`
4. Ensure username and token don't contain special characters that need URL encoding

#### Credential Helper Issues

To reset credentials:
```bash
# Remove stored credentials
docker exec multica-daemon rm ~/.git-credentials

# Restart container
docker-compose restart
```

### Common Issues (Both Methods)

#### Git User Not Configured

If commits fail due to missing user configuration, set these in your `.env`:
```bash
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"
```

## Security Best Practices

### For SSH Keys

1. **Use Read-Only Mounts**: SSH keys are mounted as read-only (`:ro`) for security
2. **Protect Your Keys**: Never commit SSH private keys to version control
3. **Use Deploy Keys**: For production, consider using deploy keys with limited access
4. **Key Passphrases**: If your SSH key has a passphrase, you'll need to use an SSH agent or remove the passphrase
5. **Principle of Least Privilege**: Give the SSH key only the minimum required permissions

### For HTTPS/PAT

1. **Secure Token Storage**: Never commit tokens to version control
2. **Use Environment Variables**: Always store tokens in `.env` files (add to `.gitignore`)
3. **Token Scoping**: Create tokens with minimum required permissions
4. **Token Rotation**: Regularly rotate tokens and revoke old ones
5. **Token Expiration**: Set expiration dates on tokens
6. **Read-Only Tokens**: For clone-only operations, use read-only tokens
7. **Separate Tokens**: Use different tokens for different projects/environments

### General

1. **Use `.gitignore`**: Ensure `.env` is in your `.gitignore`
2. **Secrets Management**: Consider using secrets management tools for production
3. **Audit Access**: Regularly review which keys/tokens have access to repositories
4. **Monitor Usage**: Monitor git activity for suspicious access patterns

## Windows Users

On Windows, adjust the SSH key path in your `.env` file:

```bash
# Windows path example
SSH_PRIVATE_KEY_PATH=C:/Users/YourUsername/.ssh/id_rsa
```

Or use WSL path:
```bash
SSH_PRIVATE_KEY_PATH=/mnt/c/Users/YourUsername/.ssh/id_rsa
```

## Example .env File

### Using SSH Key Authentication

```bash
# Multica Configuration
MULTICA_TOKEN=your-token-here
MULTICA_SERVER_URL=http://localhost:8080
MULTICA_APP_URL=http://localhost:3000

# Git SSH Configuration
SSH_PRIVATE_KEY_PATH=~/.ssh/id_rsa
GIT_USER_NAME="John Doe"
GIT_USER_EMAIL="john.doe@example.com"

# Optional: Custom SSH files
# SSH_CONFIG_PATH=~/.ssh/config
# SSH_KNOWN_HOSTS_PATH=~/.ssh/known_hosts
```

### Using HTTPS with Personal Access Token

```bash
# Multica Configuration
MULTICA_TOKEN=your-token-here
MULTICA_SERVER_URL=http://localhost:8080
MULTICA_APP_URL=http://localhost:3000

# Git HTTPS Configuration (alternative to SSH)
GIT_USERNAME=johndoe
GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GIT_CREDENTIAL_HELPER=store
GIT_USER_NAME="John Doe"
GIT_USER_EMAIL="john.doe@example.com"
```

### Using Both (SSH as primary, HTTPS as fallback)

```bash
# Multica Configuration
MULTICA_TOKEN=your-token-here
MULTICA_SERVER_URL=http://localhost:8080
MULTICA_APP_URL=http://localhost:3000

# Git Configuration - Both methods configured
# SSH will be used for git@github.com URLs
SSH_PRIVATE_KEY_PATH=~/.ssh/id_rsa

# HTTPS will be used for https://github.com URLs
GIT_USERNAME=johndoe
GIT_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GIT_CREDENTIAL_HELPER=store

# User configuration
GIT_USER_NAME="John Doe"
GIT_USER_EMAIL="john.doe@example.com"
```
