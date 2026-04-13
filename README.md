# Week-04 Ralph Loop Assignment

## Overview

This repository is a Week-04 submission that demonstrates a Ralph loop around a small typed calculator task.

## Repository Structure

- `calculator.py` contains the production implementation for `add`, `subtract`, and `divide`.
- `tests/test_calculator.py` stays in the required location and uses Python's built-in `unittest` framework.
- `PROMPT.md` provides the sequential task checklist that the loop feeds into Codex.
- `AGENTS.md` works as loop memory for code-level failure causes and successful implementation patterns.
- `harness.sh` is the main Ralph loop driver.
- `loop_log.txt` stores the accumulated output from repeated loop runs.

## Ralph Loop Structure

`harness.sh` runs a true loop with a default of three iterations. Each iteration performs the same sequence:

1. Run Codex with `PROMPT.md`.
2. Run the `unittest` suite as the verification gate.
3. If tests pass, append a success pattern to `AGENTS.md` and create a Git commit.
4. If tests fail, classify the code-level failure cause, append it to `AGENTS.md`, and run `git checkout .` as recovery.
5. Append all console output to `loop_log.txt`.

This keeps the repository aligned with the Ralph loop idea of repeated generation, evaluation, memory update, and cleanup.

## Backpressure And Garbage Collection

The harness treats test execution as a backpressure step. A loop iteration is not allowed to progress to the success path until the test suite passes. When `timeout` is available, the test command is bounded by `TEST_TIMEOUT_SECONDS`, which prevents a bad iteration from consuming unbounded compute.

The failure path applies garbage collection with `git checkout .` when the repository is inside a Git working tree. That reset removes unsuccessful working-tree edits so the next iteration starts from a cleaner baseline.

## Test-Time Compute Scaling

This assignment connects Ralph loop behavior to test-time compute scaling. Instead of relying on a single generation attempt, the harness spends additional compute across repeated generate-and-test cycles. More loop iterations allow the system to trade extra test-time compute for a higher chance of converging on a correct implementation, while `AGENTS.md` preserves lessons learned between attempts.

## Local Verification

The calculator and test suite currently pass with:

```sh
python -m unittest discover -s tests -q
```

The current machine used for editing does not include `sh`, so `harness.sh` itself was prepared for a Unix-like shell environment but could not be executed end-to-end here.
