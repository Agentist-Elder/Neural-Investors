# GitHub Personal Access Token (PAT) Setup

This guide explains how to create and configure a GitHub Personal Access Token for automated repository file operations.

## Why Use a PAT?

A Personal Access Token allows secure, programmatic access to your GitHub repository without exposing your password. It enables:
- Reading files from the repository
- Writing/updating files directly
- Creating commits programmatically
- Managing repository content via GitHub API

## Creating Your GitHub PAT

### Step 1: Navigate to GitHub Settings

1. Go to GitHub.com and sign in
2. Click your profile picture (top right) → **Settings**
3. Scroll down the left sidebar → Click **Developer settings**
4. Click **Personal access tokens** → **Tokens (classic)**
5. Click **Generate new token** → **Generate new token (classic)**

### Step 2: Configure Token Permissions

**Token Name:** `Neural-Investors-Repo-Access` (or any descriptive name)

**Expiration:** Choose based on your needs:
- 30 days (recommended for testing)
- 90 days (recommended for active development)
- No expiration (use with caution - for long-term automation)

**Required Scopes:**
- ✅ **repo** (Full control of private repositories)
  - This includes:
    - `repo:status` - Access commit status
    - `repo_deployment` - Access deployment status
    - `public_repo` - Access public repositories
    - `repo:invite` - Access repository invitations
    - `security_events` - Read and write security events

### Step 3: Generate and Copy Token

1. Click **Generate token** at the bottom
2. **IMPORTANT:** Copy the token immediately - you won't see it again!
3. Store it in a secure location temporarily (password manager recommended)

## Configuring Your Local Environment

### Step 1: Add Token to .env File

1. Open your `.env` file in the Neural-Investors directory
2. Find the `GITHUB_PAT` line (around line 63)
3. Replace `your_github_personal_access_token_here` with your actual token:

```env
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_OWNER=Agentist-Elder
GITHUB_REPO=Neural-Investors
GITHUB_API_URL=https://api.github.com
GITHUB_BRANCH=main
```

### Step 2: Verify Configuration

The configuration includes:
- `GITHUB_PAT` - Your personal access token
- `GITHUB_OWNER` - Repository owner (Agentist-Elder)
- `GITHUB_REPO` - Repository name (Neural-Investors)
- `GITHUB_API_URL` - GitHub API endpoint
- `GITHUB_BRANCH` - Default branch for operations (main)

## Security Best Practices

### DO:
✅ Store PAT in `.env` file (already in `.gitignore`)
✅ Use descriptive token names
✅ Set appropriate expiration dates
✅ Revoke tokens when no longer needed
✅ Use minimal required scopes
✅ Rotate tokens periodically

### DON'T:
❌ Commit `.env` file to git (it's already gitignored)
❌ Share your token in chat, email, or public forums
❌ Use the same token across multiple projects
❌ Grant more permissions than needed
❌ Use "no expiration" unless absolutely necessary

## Verifying Your Setup

Once configured, automated tools can:

1. **Read Files:**
   ```bash
   curl -H "Authorization: token $GITHUB_PAT" \
        https://api.github.com/repos/Agentist-Elder/Neural-Investors/contents/README.md
   ```

2. **Write Files:**
   - Create new files via GitHub API
   - Update existing files
   - Commit changes programmatically

## Revoking a Token

If your token is compromised or no longer needed:

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Find your token in the list
3. Click **Delete** or **Revoke**
4. Generate a new token if needed

## Troubleshooting

### Error: "Bad credentials"
- Token may be expired or invalid
- Regenerate a new token

### Error: "Not Found" or "403 Forbidden"
- Check token has `repo` scope enabled
- Verify repository name and owner are correct
- Ensure token hasn't been revoked

### Token Not Working
- Ensure no extra spaces when copying token
- Check token is properly set in `.env` file
- Restart any applications that load the `.env` file

## What This Enables

With this configuration, AI assistants and automation tools can:

1. **Direct File Operations:**
   - Read repository files without manual copy/paste
   - Write changes directly to repository
   - Create commits automatically

2. **Workflow Automation:**
   - Automated code updates
   - Documentation generation
   - Configuration management

3. **Version Control:**
   - All changes are tracked via git commits
   - Full audit trail of modifications
   - Easy rollback if needed

## Current Configuration

```env
Repository: Agentist-Elder/Neural-Investors
Branch: main (or claude/add-env-repo-calls-011CUy2AscJwmRQdZZixbZW8 for development)
API: https://api.github.com
```

## Additional Resources

- [GitHub PAT Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub REST API](https://docs.github.com/en/rest)
- [Repository Contents API](https://docs.github.com/en/rest/repos/contents)

## Support

If you encounter issues:
1. Check this documentation first
2. Verify token permissions and expiration
3. Review GitHub API status: https://www.githubstatus.com/
4. Regenerate token if needed

---

**Last Updated:** 2025-11-09
**Status:** Ready for Use
