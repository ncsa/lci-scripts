---
description: Design test coverage strategy with test-architect guidance
agent: test-architect
subtask: true
---
# Test Design Command

Plan comprehensive test coverage strategy for new or existing code using the test-architect subagent.

## Phase 1: Understand the Target

Analyze what needs testing:

1. If `$ARGUMENTS` provided, focus on specified files/features
2. Read the target code and understand:
   - Public interfaces and contracts
   - Business logic and edge cases
   - Dependencies and integrations
   - Error handling paths

## Phase 2: Test Pyramid Analysis

Determine appropriate test distribution:

```
         /\
        /  \  E2E Tests (Few)
       /----\  - Critical user journeys
      /      \ - Cross-system validation
     /--------\
    /          \ Integration Tests (Some)
   /            \ - API contracts
  /              \ - Database interactions
 /----------------\ - External service mocks
/                  \
/    Unit Tests     \ (Many)
/    (Foundation)    \
/----------------------\
```

### Unit Test Candidates
- Pure functions
- Business logic
- Data transformations
- Validation rules
- Edge cases and boundaries

### Integration Test Candidates
- API endpoints
- Database operations
- Message queues
- External service calls
- Authentication flows

### E2E Test Candidates
- Critical user journeys
- Checkout/payment flows
- Authentication sequences
- Multi-step workflows

## Phase 3: Test Case Generation

For each identified test target, design:

### Test Case Template
```
Feature: [Feature Name]
Scenario: [Scenario Description]
  Given: [Initial State]
  When: [Action Taken]
  Then: [Expected Outcome]

Edge Cases:
  - [Edge case 1]
  - [Edge case 2]

Error Cases:
  - [Error scenario 1]
  - [Error scenario 2]
```

### Coverage Strategy
- Happy path (normal flow)
- Boundary conditions
- Error handling
- Null/undefined inputs
- Concurrent access (if applicable)
- Performance constraints

## Phase 4: Framework Detection & Setup

Detect existing test infrastructure:
- Jest/Vitest for JavaScript/TypeScript
- pytest for Python
- go test for Go
- JUnit for Java

If no test framework exists, recommend one based on:
- Project type and language
- Team familiarity
- CI/CD compatibility
- Mocking capabilities needed

## Phase 5: Test Plan Output

```
Test Coverage Strategy
======================

Target: [Feature/Module being tested]

Test Distribution:
------------------
Unit Tests: [X tests planned]
Integration Tests: [Y tests planned]
E2E Tests: [Z tests planned]

Detailed Test Cases:
--------------------

## Unit Tests

### [Function/Method Name]
1. Test: [Description]
   - Input: [input]
   - Expected: [output]
   - Rationale: [why this test matters]

2. Test: [Description]
   ...

## Integration Tests

### [API Endpoint / Integration Point]
1. Test: [Description]
   - Setup: [required state]
   - Action: [HTTP call / operation]
   - Verify: [expected response/state]

## E2E Tests

### [User Journey Name]
1. Steps:
   - Navigate to [page]
   - Perform [action]
   - Verify [outcome]

Implementation Priority:
------------------------
1. [High priority - covers critical path]
2. [Medium priority - covers edge cases]
3. [Lower priority - nice to have]

Estimated Coverage:
-------------------
Lines: [X%]
Branches: [Y%]
Functions: [Z%]

Mocking Requirements:
---------------------
- [External service 1]: Mock with [strategy]
- [Database]: Use [in-memory / test container]

Test Data Requirements:
-----------------------
- [Fixture 1]: [description]
- [Fixture 2]: [description]
```

## Arguments

- `$ARGUMENTS` - Files, functions, or features to design tests for
- Examples:
  - `/test-design src/auth/login.ts` - Design tests for login module
  - `/test-design "user registration flow"` - Design tests for a feature
  - `/test-design` - Analyze codebase and suggest overall test strategy

## Best Practices Applied

1. **Test behavior, not implementation** - Tests should verify outcomes
2. **One assertion per test** - Keep tests focused
3. **Descriptive test names** - Should read like documentation
4. **Arrange-Act-Assert** - Clear test structure
5. **Isolated tests** - No shared state between tests
6. **Fast feedback** - Unit tests should run in milliseconds
