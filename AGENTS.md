# AGENTS.md

Working rules for the `codex-AGV-order-cancellation` project.

## Project Focus

This repository studies order cancellation dynamic rescheduling on top of the
original `codex-AGV` FJSP-AGV scheduling code.

Order cancellation must be treated as a separate disturbance from machine
failure. Do not mix machine breakdown, repair windows, or machine-failure
rescheduling logic into this project unless the user explicitly starts a later
combined-disturbance stage.

## Core Rules

1. Preserve reproducibility above all else.
2. Do one small task at a time.
3. Do not refactor unrelated code.
4. Do not change algorithm logic unless explicitly requested.
5. Prefer clarity and stability over abstraction.
6. Avoid over-engineering.

## File Safety

1. Never modify files in `raw_code/`.
2. Never delete files automatically.
3. Never overwrite `outputs/` without confirmation.
4. Use relative paths in project code and docs.
5. Do not hardcode local machine paths.
6. Generated outputs and logs must go under `outputs/`.

## Execution Policy

Static analysis is the default.

Ask for confirmation before:

1. Running MATLAB.
2. Launching experiments.
3. Generating outputs.
4. Editing multiple unrelated files.
5. Copying additional source batches from another repository.

## Project Structure

```text
raw_code/       Original archived codex-AGV code. Read-only.
src/            Refactored production code migrated from codex-AGV.
configs/        MATLAB configuration files.
scripts/        Reproducible run entries.
tests/          Lightweight reproducibility tests.
data_sample/    Minimal runnable datasets.
docs/           Plans, source maps, and reproduction notes.
outputs/        Generated outputs and logs. Not committed.
```

## Order Cancellation Scope

First-stage scope:

1. Single order cancellation.
2. Known cancellation time.
3. Machine and AGV resources are healthy.
4. Cancel only unfinished work of the cancelled order.
5. Freeze completed tasks before cancellation time.
6. Compare local repair and complete rescheduling.

Out of scope for the first stage:

1. Machine failure.
2. Multiple cancellations.
3. New order insertion.
4. AGV failure.
5. Uncertain repair/cancellation times.
6. Global optimality proof.

## Research Workflow

For every implementation step:

1. State assumptions and scope.
2. Identify the smallest affected modules.
3. Add or update a lightweight test first when feasible.
4. Implement the smallest useful change.
5. Verify with static checks or small sample tests.
6. Report changed files, purpose, test result, and remaining risk.

## Source Migration Rule

The original `codex-AGV` code was migrated to preserve a working scheduling
baseline. Treat migrated source as a baseline until the order-cancellation
extension point is clear.

Do not rewrite the original decoding, evaluation, or NSGA-II layers globally.
Add order-cancellation functionality through narrow wrappers or new modules
first.

