---
name: git-user-manual
description: Comprehensive Git workflows and usage patterns from the official Git user manual. Use when: (1) learning Git workflows for different user roles (individual, integrator, administrator, contributor), (2) understanding Git branching, merging, and patch workflows, (3) implementing collaborative development patterns, (4) setting up and configuring Git repositories, (5) troubleshooting Git operations like rebasing, cherry-picking, or history rewriting. Includes multi-step procedures, best practices, and practical examples for common Git scenarios.
---

# Git User Manual

The Git user manual provides comprehensive workflows for different roles and skill levels. This skill extracts and organizes the core concepts and procedures.

## Core Workflows

### For Individual Developers

**Basic workflow:**
- Initialize a repository: `git init` or clone existing: `git clone <url>`
- Create branches for features: `git checkout -b feature-name`
- Stage and commit changes: `git add <files>` → `git commit -m "message"`
- Push to remote: `git push origin feature-name`

**Key commands:**
- `git status` — View current state
- `git log --oneline` — View commit history
- `git diff` — Compare working directory with staging area
- `git diff HEAD` — Compare with last commit

### For Integrators (Maintainers)

**Merge-based workflow:**
- Accept pull requests or patches from contributors
- Review changes: `git log origin/incoming-branch`
- Merge into main branch: `git merge origin/incoming-branch`
- Manage releases and versioning

**Key commands:**
- `git fetch origin` — Get latest from remote
- `git merge --no-ff <branch>` — Merge with merge commit (preserves history)
- `git tag -a v1.0 -m "Release 1.0"` — Create release tags

### For Contributors (Patch Workflow)

**Patch-based collaboration (for projects accepting patches via email):**
- Create feature branch: `git checkout -b feature`
- Make commits: `git commit -m "message"`
- Generate patches: `git format-patch origin/master` (creates .patch files)
- Send patches: `git send-email *.patch` or email manually
- Update based on feedback: add commits and regenerate patches

**Key commands:**
- `git format-patch <base>` — Generate patch files
- `git apply <patch-file>` — Apply a patch
- `git am <patch-file>` — Apply and create commit from patch

### For Administrators

**Repository setup and maintenance:**
- Initialize bare repository: `git init --bare my-repo.git`
- Configure access (SSH keys, permissions)
- Set up hooks for automated workflows
- Monitor and maintain repository health

**Key commands:**
- `git fsck` — Verify repository integrity
- `git gc` — Clean up and optimize repository
- `git config --system` — System-wide configuration

## Branching Strategies

### Feature Branching

1. Create branch from main: `git checkout -b feature/user-auth`
2. Work and commit: Multiple commits as you develop
3. Merge back: `git checkout main` → `git merge feature/user-auth`
4. Delete branch: `git branch -d feature/user-auth`

### Release Branching

For managing releases separate from development:
1. Create release branch: `git checkout -b release/v1.0`
2. Final fixes and version bumps on release branch
3. Merge back to main: `git merge release/v1.0`
4. Tag the release: `git tag -a v1.0`
5. Cherry-pick critical fixes to main if needed

## Rebasing and History

### When to Rebase

Use rebasing to:
- **Clean up local history before sharing** — Rewrite commits to be clear and focused
- **Keep feature branch up to date** — Rebase on updated main branch
- **Squash work-in-progress commits** — Combine multiple commits into logical units

**Do NOT rebase:**
- After pushing (unless all collaborators know)
- On shared branches (main, develop)
- If rewriting history affects others

### Interactive Rebase

```bash
git rebase -i HEAD~3
```

Allows you to:
- `pick` — Keep commit as-is
- `reword` — Change commit message
- `squash` — Combine with previous commit
- `drop` — Remove commit entirely

### Cherry-Picking

Apply specific commits to another branch:
```bash
git cherry-pick <commit-hash>
```

Useful for:
- Backporting fixes to older release branches
- Applying specific commits from another feature branch
- Emergency fixes that need multiple branches

## Merging Strategies

### Three-Way Merge (Default)

```bash
git merge <branch>
```

Creates a merge commit with two parents. Best for:
- Integrating completed features
- Preserving clear history of integration points

### Squash Merge

```bash
git merge --squash <branch>
git commit -m "Merge feature: ..."
```

Combines all commits into one. Best for:
- Cleaning up messy feature branches
- Treating feature as atomic unit in main history

### Fast-Forward Merge

```bash
git merge --ff-only <branch>
```

Only works if no divergence. Best for:
- Simple linear histories
- Keeping history clean when no real merge occurs

## Working with Remotes

### Tracking Branches

When you clone or checkout a remote branch, Git automatically creates a tracking branch that follows the remote:
```bash
git checkout -b local-branch origin/remote-branch
# or (shorthand)
git checkout remote-branch
```

Tracking branches automatically know where to push/pull from.

### Fetching vs Pulling

- **Fetch:** `git fetch origin` — Get updates from remote, don't merge
  - Safe, doesn't modify working directory
  - Use to review changes before merging
  
- **Pull:** `git pull origin main` — Fetch + merge in one step
  - Convenient but risky if you don't review
  - Can cause unexpected merges

### Pushing

```bash
git push origin feature-branch
```

Push to remote. If tracking branch exists, can use shorthand:
```bash
git push
```

Delete remote branch:
```bash
git push origin --delete old-branch
```

## Advanced Patterns

### Stashing Work-in-Progress

Save uncommitted changes temporarily:
```bash
git stash
# ... switch branches or clean up
git stash pop  # or git stash apply
```

List all stashes:
```bash
git stash list
```

### Reflog: Undo Almost Anything

Git keeps a log of where HEAD has been:
```bash
git reflog
# Find the commit you want
git checkout <commit-hash>
# Or reset to it
git reset --hard <commit-hash>
```

Useful for recovering from accidental resets or rebases.

### Blame and History

Find who changed what:
```bash
git blame <file>
```

See all changes to a line:
```bash
git log -p -S <search-term>
```

## Best Practices

1. **Write clear commit messages** — First line is summary, then blank line, then details
2. **Commit logical units** — Each commit should be a self-contained change
3. **Review before pushing** — Use `git diff` and `git log` to check your work
4. **Keep local, share selectively** — Rebase and organize local commits before pushing
5. **Never force-push shared branches** — Only rewrite history on personal branches
6. **Use tags for releases** — Mark important points with meaningful tags
7. **Automate with hooks** — Use `.git/hooks/` for validation and automation

## Troubleshooting

### Undo Last Commit (Not Pushed)

Keep the changes:
```bash
git reset --soft HEAD~1
```

Discard the changes:
```bash
git reset --hard HEAD~1
```

### Fix Mistake in Last Commit

```bash
# Change the message
git commit --amend -m "corrected message"

# Add forgotten files
git add forgotten_file
git commit --amend --no-edit
```

### Revert a Commit (Already Pushed)

Create a new commit that undoes changes:
```bash
git revert <commit-hash>
```

### Find a Lost Commit

```bash
git fsck --lost-found
```

Then examine the dangling commits in `.git/lost-found/`.

## References

- Official docs: https://git-scm.com/docs/user-manual
- Git book: https://git-scm.com/book/en/v2
- Quick reference: https://git-scm.com/docs
