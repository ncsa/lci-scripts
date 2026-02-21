---
description: Generate documentation (API docs, READMEs, guides)
agent: docs-writer
subtask: true
---
# Documentation Generation Command

Generate comprehensive documentation using the docs-writer subagent. Creates API documentation, READMEs, and developer guides.

## Phase 1: Documentation Discovery

Determine documentation needs:

1. If `$ARGUMENTS` specifies type (api, readme, guide), focus on that
2. Otherwise, analyze project to identify documentation gaps:
   - Missing README.md
   - Undocumented APIs
   - Missing inline comments
   - Outdated documentation

## Phase 2: Context Gathering

Collect information for documentation:

### For API Documentation
- Read source files with public interfaces
- Extract function signatures, parameters, return types
- Find existing JSDoc/docstrings
- Identify example usage in tests

### For README
- Read package.json / pyproject.toml for project metadata
- Check existing README for structure to maintain
- Look for setup scripts and configuration
- Find example code or demos

### For Guides
- Understand the feature/workflow being documented
- Identify prerequisites and dependencies
- Find related code and configuration

## Phase 3: Documentation Generation

### API Documentation Template

```markdown
# API Reference

## Module: [module_name]

### `functionName(param1, param2)`

Brief description of what this function does.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | string | Yes | Description |
| param2 | Options | No | Configuration options |

**Returns:** `ReturnType` - Description of return value

**Throws:**
- `ErrorType` - When condition occurs

**Example:**
\`\`\`typescript
const result = functionName('value', { option: true });
\`\`\`

**See Also:** [Related Function](#related)
```

### README Template

```markdown
# Project Name

Brief description of what this project does.

## Features

- Feature 1
- Feature 2

## Installation

\`\`\`bash
npm install package-name
\`\`\`

## Quick Start

\`\`\`typescript
import { something } from 'package-name';

// Basic usage example
\`\`\`

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| option1 | string | 'default' | What it does |

## API Reference

[Link to full API docs]

## Contributing

[Contributing guidelines]

## License

[License info]
```

### Guide Template

```markdown
# How to [Accomplish Task]

## Overview

What this guide covers and who it's for.

## Prerequisites

- Requirement 1
- Requirement 2

## Step 1: [First Step]

Detailed instructions...

\`\`\`bash
# Example command
\`\`\`

## Step 2: [Second Step]

...

## Troubleshooting

### Common Issue 1
Solution...

### Common Issue 2
Solution...

## Next Steps

- [Related Guide 1]
- [Related Guide 2]
```

## Phase 4: Quality Checks

Before outputting documentation:

1. **Accuracy**: Verify code examples compile/run
2. **Completeness**: All public APIs documented
3. **Consistency**: Terminology and formatting uniform
4. **Freshness**: No references to deprecated features

## Phase 5: Output

Present documentation with:
- Clear section headers
- Proper markdown formatting
- Code blocks with syntax highlighting
- Tables for structured data
- Links to related documentation

```
Documentation Generated
=======================

Type: [API / README / Guide]
Target: [file or feature]

[Generated documentation content]

---
Suggestions:
- [Additional documentation that might be helpful]
- [Related updates needed]
```

## Arguments

- `$ARGUMENTS` - What to document
  - `api [file/module]` - Generate API documentation
  - `readme` - Generate or update README.md
  - `guide [topic]` - Generate a how-to guide
  - `[file]` - Auto-detect best documentation type

## Examples

```
/docs api src/auth/
/docs readme
/docs guide "setting up development environment"
/docs src/utils/helpers.ts
```

## Style Guidelines

1. **Be concise** - Developers skim documentation
2. **Show, don't tell** - Include code examples
3. **Progressive disclosure** - Simple first, details later
4. **Keep updated** - Outdated docs are worse than none
5. **Consider the audience** - Adjust technical depth
