# Test Judgment

## Purpose

- Every test must protect a concrete behavior, business rule, failure mode, or
  compatibility/security contract. Identify the regression it would catch
  before writing it.

- Describe the specific incorrect behavior the test distinguishes from correct
  behavior. “Renders correctly” or “works” is insufficient.

- Test count, coverage percentage, and passing checks do not establish test
  value. Each test must justify its maintenance cost.

## What to Test

- Prefer observable results: returned values, state changes, externally visible
  effects, rejected invalid inputs, and preserved compatibility.

- Do not write tests that merely restate the implementation: finding text in
  source code, copying configuration literals into assertions, or inventorying
  a structure already declared explicitly.

- For generated code, scripts, or configuration, test meaningful transformation
  logic or downstream behavior. Successful rendering or a matching substring
  does not establish that the generated artifact works.

- Avoid testing standard library, language, shell, or OS behavior unless our
  code adds a policy or transformation that needs protection.

- Constants, structural assertions, snapshots, and helper tests are appropriate
  when they protect a meaningful contract. Their form alone neither justifies
  nor disqualifies them.

## Scope and Structure

- Choose the smallest test boundary that exposes the regression. Pure-function
  tests suit nontrivial rules; API tests suit wiring, persistence, and side
  effects. Broader tests are not automatically better.

- Reuse existing behavioral tests before adding another test layer. Avoid
  testing the same rule through both a helper and its caller unless those tests
  protect distinct contracts.

- Keep setup, fixtures, mocking, and abstractions proportional to the behavior.
  Do not build a harness merely to verify an obvious declaration.

- Add cases for distinct risks or behaviors. Avoid mechanically expanding every
  combination of inputs when those combinations exercise the same rule.

## Fixtures and Assertions

- Choose fixtures that expose the intended mistake. When testing an update,
  make the old and requested values different.

- When testing preservation, seed values that reveal accidental recomputation
  or resetting to defaults. A default-valued fixture may let incorrect
  reconstruction pass as preservation.

- Derive expected results from the contract, independently of the implementation.
  Avoid reproducing the production algorithm inside the test.

- Assert the outcomes relevant to the regression. Compare entire objects only
  when their complete contents or preservation are part of the contract.

- For side effects, check which effects occurred and, when significant, how many
  times. Inspect the resulting operation or state rather than merely confirming
  that a helper was called.

- Make essential setup failures stop the test. Avoid misleading secondary
  failures or assertions that silently never execute.

## Demonstrating Value

- A useful test should fail when its intended behavior breaks and survive
  cosmetic refactors.

- When a test's value is uncertain, temporarily introduce the intended regression
  and confirm that the test fails for that reason—not because compilation,
  setup, or an unrelated assertion fails.

- Use temporary copies or overlays for such checks where practical. Keep
  deliberate faults out of the working implementation.

## Maintenance and Review

- When the design changes, audit all tests introduced or modified by the branch,
  including tests inherited from abandoned approaches. Remove obsolete cases,
  dead helpers, misleading names, and redundant assertions.

- Review test relevance separately from test correctness. For every added test,
  require a concrete regression rationale rather than accepting it because it
  passes or increases coverage.

- Prefer improving an existing test over adding overlapping coverage. Delete
  tests whose maintenance cost exceeds the protection they provide.

- Describe exactly what validation establishes. Static checks, mocks, and
  rendering tests must not be presented as runtime or deployment verification.
