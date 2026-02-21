---
description: Demonstrate parallel execution by launching multiple agents simultaneously
agent: build
---
# Parallel Execution Command

Demonstrates the parallel execution pattern from claude-workflow-v2 by launching multiple independent subagents in a single message.

## Core Principle

> ALL Task calls MUST be in a SINGLE assistant message for true parallelism.

If Task calls are in separate messages, they run sequentially, negating the performance benefit.

## Phase 1: Analyze the Request

Parse `$ARGUMENTS` to determine parallel tasks:

1. **Task-based**: Multiple independent tasks to execute
2. **Directory-based**: Multiple directories to analyze
3. **Perspective-based**: Multiple review angles on same code

If no arguments, demonstrate with a default parallel analysis of the project.

## Phase 2: Identify Independent Tasks

For parallelization, tasks must be:
- **Independent**: No dependencies between them
- **Non-conflicting**: Don't modify the same files
- **Self-contained**: Each can complete without the other

Examples of good parallel candidates:
- Code review + Security audit + Test analysis
- Analyze src/ + Analyze lib/ + Analyze tests/
- Check TypeScript + Check ESLint + Check tests

## Phase 3: Execute in Parallel

Launch ALL subagents in a SINGLE message using the Task tool:

```
In ONE message, spawn multiple Task calls:

Task 1: "@code-reviewer Review the authentication module for quality issues"
Task 2: "@security-auditor Check authentication for vulnerabilities"
Task 3: "@test-architect Analyze test coverage for authentication"
```

### Parallelization Patterns

#### Pattern A: Multi-Perspective Review
```
Spawn in parallel:
- Logic Reviewer: Focus on correctness and edge cases
- Performance Reviewer: Focus on efficiency and bottlenecks
- Security Reviewer: Focus on vulnerabilities
- Maintainability Reviewer: Focus on code quality
```

#### Pattern B: Directory Parallelization
```
Spawn in parallel:
- Subagent 1: Analyze src/api/
- Subagent 2: Analyze src/models/
- Subagent 3: Analyze src/utils/
```

#### Pattern C: Full Verification Suite
```
Spawn in parallel:
- Type Checker: Run TypeScript/mypy
- Linter: Run ESLint/ruff
- Test Runner: Execute test suite
- Security Scanner: Check for vulnerabilities
```

## Phase 4: Collect Results

As each subagent completes:
1. Capture their output
2. Track completion status
3. Note any conflicts or overlapping findings

## Phase 5: Synthesize

Combine all parallel outputs into unified report:

```
Parallel Execution Report
=========================

Tasks Launched: [N]
Execution Time: ~[max task time] (vs [sum of times] sequential)
Speedup: ~[N]x

Results by Subagent:
--------------------

[Subagent 1 Name]:
[Summary of findings]

[Subagent 2 Name]:
[Summary of findings]

...

Cross-Cutting Findings:
-----------------------
[Issues identified by multiple subagents]

Conflicts/Overlaps:
-------------------
[Any contradictory recommendations]

Prioritized Actions:
--------------------
1. [Most critical issue]
2. [Second priority]
...
```

## Arguments

- `$ARGUMENTS` - What to run in parallel
  - `review [files]` - Multi-perspective review
  - `analyze [dirs]` - Directory-based analysis
  - `verify` - Full verification suite
  - Custom task list separated by `|`

## Examples

```
/parallel review src/auth/
/parallel analyze src/api | src/models | src/db
/parallel verify
/parallel "check types | run tests | lint code | security scan"
```

## Performance Impact

| Approach | 4 Tasks @ 30s each | Total Time |
|----------|-------------------|------------|
| Sequential | 30s + 30s + 30s + 30s | ~120s |
| Parallel | All 4 run simultaneously | ~30s |

**Parallel execution is approximately Nx faster** where N = number of independent tasks.

## Important Notes

1. **All in ONE message**: This is critical for true parallelism
2. **No dependencies**: Only parallelize independent tasks
3. **Resource awareness**: Don't spawn excessive parallel tasks
4. **Synthesis required**: Raw parallel output needs integration
5. **Conflict resolution**: Different agents may have conflicting advice

## When NOT to Parallelize

- Tasks with dependencies (A must complete before B)
- Tasks modifying the same files
- Sequential workflows (commit -> push -> PR)
- When order matters for correctness
