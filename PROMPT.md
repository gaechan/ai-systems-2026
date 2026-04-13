# Ralph Loop Prompt

Implement the calculator incrementally and keep the repository stable at each step.

Rules:
- Follow a strict test-first workflow.
- Implement exactly one function at a time.
- Do not move or rename `tests/test_calculator.py`.
- Keep `unittest` as the test runner.
- Add type hints to every function.
- Make the smallest possible change that satisfies the current checklist item.

Checklist:
- [ ] Step 1: Confirm the `add(a: float, b: float) -> float` behavior against the existing tests, then implement only `add`.
- [ ] Step 2: Confirm the `subtract(a: float, b: float) -> float` behavior against the existing tests, then implement only `subtract`.
- [ ] Step 3: Confirm the `divide(a: float, b: float) -> float` behavior against the existing tests, then implement only `divide`.
- [ ] Step 4: Add the explicit `ZeroDivisionError` guard for `divide` when the divisor is zero.
- [ ] Step 5: Re-run the full test suite and stop only when all tests pass.
