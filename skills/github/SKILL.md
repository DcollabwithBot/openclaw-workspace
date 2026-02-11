# GitHub Integration

GitHub integration for OpenClaw using the dspammails-rgb bot account.

## Authentication

**Account:** `dspammails-rgb`
**Token:** Stored in `~/.openclaw/credentials/github`
**Scope:** Fine-grained PAT with repo access

## Organization

**Target:** `DcollabwithBot` organization
**Status:** Pending invitation/membership

## Tools

### `github_clone`
Clone a repository.

**Parameters:**
- `repo` (required): Repository name (e.g., "DcollabwithBot/myrepo")
- `path` (optional): Local path (default: workspace/repos/)
- `branch` (optional): Branch to checkout (default: main)

**Example:**
```
github_clone(repo="DcollabwithBot/project-x", path="workspace/project-x")
```

### `github_commit`
Stage, commit and push changes.

**Parameters:**
- `path` (required): Path to git repo
- `message` (required): Commit message
- `files` (optional): Specific files to stage (default: all)
- `push` (optional): Push immediately (default: true)

**Example:**
```
github_commit(
  path="workspace/project-x",
  message="feat: add new feature",
  files=["src/main.py", "README.md"]
)
```

### `github_create_pr`
Create a pull request.

**Parameters:**
- `repo` (required): Repository name
- `title` (required): PR title
- `body` (optional): PR description
- `head` (required): Branch with changes
- `base` (optional): Target branch (default: main)

**Example:**
```
github_create_pr(
  repo="DcollabwithBot/project-x",
  title="Add authentication",
  body="Implements OAuth2 login",
  head="feature/auth"
)
```

### `github_create_issue`
Create an issue.

**Parameters:**
- `repo` (required): Repository name
- `title` (required): Issue title
- `body` (optional): Issue description
- `labels` (optional): Array of label names

**Example:**
```
github_create_issue(
  repo="DcollabwithBot/project-x",
  title="Bug: Login fails",
  body="Steps to reproduce...",
  labels=["bug", "high-priority"]
)
```

### `github_list_repos`
List repositories for user or org.

**Parameters:**
- `owner` (optional): User or org name (default: authenticated user)

**Example:**
```
github_list_repos(owner="DcollabwithBot")
```

## Setup Required

Before using this skill, ensure:

1. **GitHub account created:** `dspammails-rgb` ✅
2. **PAT generated and stored:** ✅
3. **Git configured:**
   ```bash
   git config --global user.name "dspammails-rgb"
   git config --global user.email "dspammails-rgb@users.noreply.github.com"
   ```

4. **Organization access:**
   - Invite `dspammails-rgb` to `DcollabwithBot` org
   - Or add as collaborator to specific repos

## Usage Workflow

**Making changes:**
1. Clone repo: `github_clone(repo="DcollabwithBot/project")`
2. Make edits using file tools
3. Commit: `github_commit(path="workspace/project", message="fix: typo")`

**Creating PRs:**
1. Clone repo
2. Create branch: `git checkout -b feature/new-thing`
3. Make changes and commit
4. Push branch: `git push origin feature/new-thing`
5. Create PR: `github_create_pr(...)`

## Security Notes

- PAT has limited scope (fine-grained)
- Token stored with 600 permissions
- Only works with repos where account has access
- Can be revoked anytime from GitHub settings
