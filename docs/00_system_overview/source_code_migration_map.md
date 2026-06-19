# Source Code Migration Map

This document records what was migrated from `tianyueni78-cyber/codex-AGV` and
how each part should be used for the order-cancellation project.

## 1. Migration Source

Source repository:

```text
https://github.com/tianyueni78-cyber/codex-AGV
```

Target repository:

```text
https://github.com/tianyueni78-cyber/codex-AGV-order-cancellation
```

Purpose:

```text
Reuse the normal FJSP-AGV scheduling baseline before adding order cancellation.
```

## 2. Migrated Directories

| Path | Role in original project | Role in this project |
|---|---|---|
| `raw_code/` | Original archived MATLAB code and baseline behavior reference | Read-only baseline. Do not edit. |
| `src/` | Refactored source code for data, decoding, evaluation, search, metrics, and visualization | Main source base for future order-cancellation wrappers. |
| `configs/` | Small, medium, formal, independent, and baseline configuration files | Starting point for cancellation-specific configs. |
| `scripts/` | Reproducible MATLAB run entries | Starting point for future cancellation run scripts. |
| `tests/` | Lightweight tests, static checks, and raw-compare tests | Starting point for cancellation smoke tests. |
| `data_sample/` | Minimal sample data | First data source for smoke tests. |
| `docs/` | Original source maps, reproduction steps, and engineering notes | Background knowledge for understanding the migrated code. |

`outputs/` was not migrated. New generated outputs should be created locally
under `outputs/` and should not be committed.

## 3. Source Layer Map

### `src/data/`

Reads FJSP, machine, and AGV data.

Important files:

```text
src/data/read_fjsp.m
src/data/read_machine_data.m
src/data/read_agv_data.m
```

Order-cancellation use:

```text
Reuse unchanged for baseline data loading.
```

### `src/encoding/`

Builds and validates chromosome structures.

Order-cancellation use:

```text
Reuse encoding semantics for remaining unfinished operations after cancellation.
Do not change global encoding until the cancellation subset contract is defined.
```

### `src/decoding/`

Decodes chromosomes into machine and AGV schedules.

Order-cancellation use:

```text
Likely reuse through a wrapper that freezes completed tasks and excludes
cancelled unfinished operations.
```

### `src/evaluation/`

Evaluates decoded schedules and objective values.

Order-cancellation use:

```text
Reuse makespan and energy calculations.
Add cancellation-specific disruption metrics separately.
```

### `src/search/`

Contains independent NSGA-II search logic.

Order-cancellation use:

```text
Use as the first complete-rescheduling baseline after the cancellation problem
has been reduced to remaining unfinished operations.
```

### `src/metrics/`

Computes Pareto and multi-objective quality metrics.

Order-cancellation use:

```text
Reuse for Pareto summaries. Add order-cancellation strategy metrics such as
Cmax_delta, SD, TD, and Y in a separate module when implementation begins.
```

### `src/visualization/`

Generates visualization artifacts such as Gantt charts and result plots.

Order-cancellation use:

```text
Reuse later for comparing original, local-repair, and complete-reschedule plans.
```

## 4. Planned New Order-Cancellation Modules

Do not implement these until the baseline call chain is confirmed.

Suggested future locations:

```text
src/cancellation/create_order_cancellation_event.m
src/cancellation/validate_order_cancellation_event.m
src/cancellation/extract_cancellation_state.m
src/rescheduling/build_order_cancel_local_repair.m
src/rescheduling/build_order_cancel_frozen_problem.m
src/rescheduling/decode_order_cancel_complete_reschedule.m
src/evaluation/evaluate_order_cancel_candidate.m
```

Suggested future scripts:

```text
scripts/run_order_cancel_state_smoke.m
scripts/run_order_cancel_local_repair_smoke.m
scripts/run_order_cancel_complete_reschedule_smoke.m
scripts/run_order_cancel_strategy_comparison.m
```

Suggested future tests:

```text
tests/test_order_cancellation_event.m
tests/test_order_cancellation_state.m
tests/test_order_cancel_local_repair.m
tests/test_order_cancel_strategy_metrics.m
```

## 5. First Safe Next Step

The first implementation task should be static and narrow:

```text
Identify the normal scheduling call chain in the migrated codex-AGV source.
Do not run MATLAB.
Do not generate outputs.
Do not modify raw_code/.
```

Expected evidence:

```text
A short document or README section listing the data loading, decoding, AGV,
evaluation, and NSGA-II entry points that order cancellation will reuse.
```

