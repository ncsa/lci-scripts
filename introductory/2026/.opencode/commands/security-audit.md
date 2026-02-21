---
description: Security audit with OWASP Top 10 vulnerability check
agent: security-auditor
subtask: true
---
# Security Audit Command

Perform a comprehensive security audit of the codebase or specific files, checking for OWASP Top 10 vulnerabilities and common security issues.

## Phase 1: Scope Identification

Determine audit scope:
1. If `$ARGUMENTS` provided, focus on specified files/directories
2. If no arguments, audit recently changed files via `git diff --name-only HEAD~5`
3. Identify file types and relevant security concerns for each

## Phase 2: OWASP Top 10 Analysis

Check for each OWASP Top 10 (2021) vulnerability:

### A01: Broken Access Control
- Missing authorization checks
- IDOR vulnerabilities
- Path traversal risks
- Privilege escalation possibilities

### A02: Cryptographic Failures
- Hardcoded secrets or API keys
- Weak encryption algorithms
- Missing encryption for sensitive data
- Insecure random number generation

### A03: Injection
- SQL injection vectors
- Command injection risks
- XSS vulnerabilities
- Template injection
- LDAP/XML injection

### A04: Insecure Design
- Missing rate limiting
- Lack of input validation
- Trust boundary violations
- Missing security controls

### A05: Security Misconfiguration
- Debug mode in production
- Default credentials
- Overly permissive CORS
- Missing security headers
- Exposed error messages

### A06: Vulnerable Components
- Check package.json / requirements.txt / go.mod for known vulnerabilities
- Outdated dependencies
- Deprecated functions

### A07: Authentication Failures
- Weak password policies
- Missing MFA considerations
- Session management issues
- Credential stuffing vectors

### A08: Software and Data Integrity Failures
- Missing integrity checks
- Insecure deserialization
- Unsigned updates or data

### A09: Security Logging Failures
- Missing audit logs
- Sensitive data in logs
- Insufficient monitoring

### A10: Server-Side Request Forgery (SSRF)
- Unvalidated URLs
- Internal network access risks
- Cloud metadata exposure

## Phase 3: Code Pattern Analysis

Search for dangerous patterns:

```
Patterns to detect:
- eval(), exec(), system() calls with user input
- Unsanitized SQL queries
- innerHTML with user data
- Disabled security features (verify=False, etc.)
- Hardcoded credentials (password=, secret=, api_key=)
- Debug/verbose modes
- TODO/FIXME security comments
```

## Phase 4: Dependency Audit

If applicable, run:
- `npm audit` for Node.js projects
- `pip-audit` or `safety check` for Python
- `go list -m -json all | nancy sleuth` for Go
- Review lockfile for unexpected changes

## Phase 5: Report Generation

```
Security Audit Report
=====================
Scope: [files/directories audited]
Date: [timestamp]

CRITICAL FINDINGS (Fix Immediately):
------------------------------------
[List with file:line references]

HIGH SEVERITY:
--------------
[List with file:line references]

MEDIUM SEVERITY:
----------------
[List with file:line references]

LOW SEVERITY / INFORMATIONAL:
-----------------------------
[List with file:line references]

OWASP Coverage:
---------------
A01 Broken Access Control: [Checked/Issues Found]
A02 Cryptographic Failures: [Checked/Issues Found]
...

Recommendations:
----------------
1. [Prioritized action items]

Dependencies:
-------------
[Vulnerable packages if any]
```

## Severity Classification

- **CRITICAL**: Actively exploitable, data breach risk
- **HIGH**: Exploitable with some effort, significant impact
- **MEDIUM**: Requires specific conditions, moderate impact
- **LOW**: Minimal impact or unlikely to be exploited
- **INFORMATIONAL**: Best practice suggestions

## Arguments

- `$ARGUMENTS` - Files or directories to audit (optional)
- If empty, audits recent changes
- Use `--full` to audit entire codebase
