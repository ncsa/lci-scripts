---
description: Create git commit with auto-generated conventional commit message
agent: build
---
# Git Commit Command

Create a well-structured git commit by analyzing staged changes and generating a conventional commit message.

## Phase 1: Gather Context

Run these commands in parallel to understand the current state:

1. `git status` - See all staged and unstaged changes
2. `git diff --cached` - View the actual staged changes that will be committed
3. `git log --oneline -5` - Review recent commit message style for consistency

## Phase 2: Analyze Changes

Based on the staged diff, determine:

1. **Change Type** (use conventional commits):
   - `feat`: New feature
   - `fix`: Bug fix
   - `refactor`: Code restructuring without behavior change
   - `docs`: Documentation only
   - `test`: Adding or updating tests
   - `chore`: Maintenance tasks
   - `style`: Formatting, whitespace
   - `perf`: Performance improvement
   - `ci`: CI/CD changes

2. **Scope** (optional): Affected module or component

3. **Description**: Concise summary focusing on WHY, not WHAT

## Phase 3: Generate Commit Message

Format: `type(scope): description`

Rules:
- Use imperative mood ("Add feature" not "Added feature")
- Keep first line under 72 characters
- Focus on the purpose and impact
- Add body for complex changes explaining reasoning

## Phase 4: Execute Commit

1. If there are unstaged changes that should be included, ask user first
2. Stage any additional files if requested
3. Execute the commit with the generated message
4. Run `git status` to verify success

## Output Format

```
Commit Analysis
---------------
Type: [type]
Scope: [scope or "none"]
Files: [number] files changed

Generated Message:
[commit message]

Commit Status: [success/failure]
```

## Safety Checks

- NEVER commit files that appear to contain secrets (.env, credentials, API keys)
- WARN if committing lock files or large binary files
- CONFIRM before committing if there are untracked files that might be forgotten
