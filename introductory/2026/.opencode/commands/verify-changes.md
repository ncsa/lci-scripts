---
description: Multi-phase verification of implementation with adversarial review
agent: build
---
# Verify Changes Command

Comprehensive verification of recent changes using the adversarial verification approach from claude-workflow-v2.

## Philosophy

Use progressive quality gates - run cheap checks first, expensive checks later. If early checks fail, stop immediately to save time.

## Phase 1: Gather Context

Run in parallel:
1. `git diff HEAD~1` or `git diff` - Understand what changed
2. `git status` - See current state
3. Identify affected files and their types (source, test, config)

## Phase 2: Fast Checks (Fail-Fast Gate)

Run these quick checks first (~5-30 seconds each). Stop on first failure:

### Lint Check
- Detect project linter (eslint, prettier, ruff, golint, etc.)
- Run: `npm run lint` or equivalent
- Exit immediately if lint fails

### Type Check
- Detect type system (TypeScript, mypy, etc.)
- Run: `npx tsc --noEmit` or equivalent
- Exit immediately if type errors exist

### Build Check
- Run: `npm run build` or equivalent
- Verify compilation succeeds

## Phase 3: Deep Checks (Quality Gate)

Only proceed if Phase 2 passes:

### Test Execution
- Run: `npm test` or equivalent
- Capture test results and coverage if available
- Report any failing tests with details

### Security Scan (if security-auditor agent available)
- Invoke @security-auditor for OWASP top 10 review
- Check for obvious vulnerabilities in changed code

## Phase 4: Adversarial Review

Spawn parallel verification subagents (if Task tool available):

1. **Logic Reviewer**: "Review the changed code for logical errors, edge cases, and potential bugs"
2. **Consistency Checker**: "Verify the changes are consistent with existing codebase patterns"
3. **Test Coverage Analyzer**: "Check if new code has adequate test coverage"

## Phase 5: Synthesize Results

Compile findings from all phases:

```
Verification Report
===================

Fast Checks (Phase 2):
  [ ] Lint Check: [PASS/FAIL]
  [ ] Type Check: [PASS/FAIL]
  [ ] Build Check: [PASS/FAIL]

Deep Checks (Phase 3):
  [ ] Tests: [X passed, Y failed]
  [ ] Security: [issues found / clean]

Adversarial Review (Phase 4):
  - Logic Issues: [list]
  - Consistency Issues: [list]
  - Coverage Gaps: [list]

Overall Status: [READY TO MERGE / NEEDS WORK]

Recommended Actions:
1. [action item]
2. [action item]
```

## Arguments

- `$ARGUMENTS` - Optional: specific files or directories to verify
- If no arguments, verify all recent changes

## Configuration Detection

Automatically detect project configuration:
- package.json -> npm/yarn commands
- pyproject.toml / setup.py -> Python commands
- Cargo.toml -> Rust commands
- go.mod -> Go commands
- Makefile -> make commands

## Error Handling

If a check fails:
1. Report the specific error with context
2. Suggest a fix if possible
3. Ask user if they want to continue with remaining checks or stop
