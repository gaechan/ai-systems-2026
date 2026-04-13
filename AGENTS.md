# Ralph Loop Notes

## Purpose
- Track code-level failure causes and reusable success patterns while iterating on the calculator task.

## Failure Recording Rule
- Record the direct code cause of the failing run, not just the command exit code.
- Prefer categories such as type error, logic error, import error, syntax error, missing function, or missing zero-division handling.
- Tie each failure note to a specific calculator behavior when possible.

## Success Recording Rule
- Record concise implementation patterns that led to a passing `unittest` run.
- Prefer patterns that are reusable in the next Ralph loop iteration.

## Failure Cause Examples
- Type error caused by passing or returning a value with the wrong runtime type.
- Logic error caused by `add`, `subtract`, or `divide` returning the wrong arithmetic result.
- Import or attribute error caused by a missing `calculator.py` symbol.
- Zero-division handling omission where `divide` does not raise `ZeroDivisionError`.
- Syntax error introduced while editing the calculator implementation.

## Current Success Pattern
- Tests pass when `calculator.py` exposes typed `add`, `subtract`, and `divide` functions and `divide` raises `ZeroDivisionError` for a zero divisor.

## Failure Pattern
- Timestamp: 2026-04-13
- Code Cause: Initial verification with `python -m pytest -q` failed because the environment did not include `pytest`, so the standard-library runner was required.

## Failure Pattern
- Timestamp: 2026-04-13
- Code Cause: `harness.sh` could not be executed in the current Windows PowerShell environment because no POSIX shell (`bash` or `sh`) was installed.

## Failure Pattern
- Timestamp: 2026-04-13
- Code Cause: `divide()` returned a numeric result for a zero divisor instead of raising `ZeroDivisionError`, so the zero-division guard had to be added explicitly.

## Failure Pattern
- Timestamp: 2026-04-13
- Code Cause: `subtract()` used the operands in reverse order, which caused a logic error and broke the expected arithmetic result in `test_subtract`.

## Success Pattern
- Timestamp: 2026-04-13
- Pattern: `python -m unittest discover -s tests -q` passed once the calculator exposed typed `add`, `subtract`, and guarded `divide` behavior.
