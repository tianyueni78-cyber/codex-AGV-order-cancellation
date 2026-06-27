# Order Cancellation Reproduction Guide

## Project Goal

This project provides a code prototype for intelligent scheduling under order cancellation. The current scope is single-order cancellation in an FJSP-AGV schedule, with reproducible random cancellation cases.

## Current Capabilities

- Single random order cancellation demo.
- Batch random order cancellation entry.
- Controllable `seed`.
- Controllable `cancel_time`.
- Controllable `dataset`.
- CSV output for traceability.
- Entry into the existing order cancellation repair/rescheduling chain.
- Freeze-delete-candidate-selection workflow:
  - freeze completed tasks before the cancellation time;
  - delete unfinished tasks of the cancelled order;
  - build local repair and complete rescheduling candidates;
  - select a strategy using multiple metrics.

## Single Demo

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
run('scripts/run_random_order_cancellation_demo.m')
```

## Small Batch

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
seeds = 1:3;
cancelTimes = [5 9];
datasets = {'data_sample/Mk01.fjs'};
run('scripts/run_random_order_cancellation_batch.m')
```

## 90-Row Batch

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
seeds = 1:30;
cancelTimes = [5 9 13];
datasets = {'data_sample/Mk01.fjs'};
run('scripts/run_random_order_cancellation_batch.m')
```

## 700-Row Large Batch

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
seeds = 1:100;
cancelTimes = [3 5 7 9 11 13 15];
datasets = {'data_sample/Mk01.fjs'};
run('scripts/run_random_order_cancellation_batch.m')
```

## Output Directory

Batch outputs are written under:

```text
outputs/batch_random_order_cancellation/<timestamp>/batch_random_order_cancellation.csv
```

Known completed batch outputs include:

- `outputs/batch_random_order_cancellation/20260627_131427/batch_random_order_cancellation.csv`
- `outputs/batch_random_order_cancellation/20260627_131448/batch_random_order_cancellation.csv`
- `outputs/batch_random_order_cancellation/20260627_131510/batch_random_order_cancellation.csv`

## CSV Fields

- `dataset`: dataset path used by the run.
- `seed`: random seed used to select the cancelled order.
- `cancel_time`: cancellation time.
- `canceled_order_id`: randomly selected cancelled order ID.
- `cancel_job_id`: equivalent cancelled job/order ID if produced by another result file.
- `selected_strategy`: selected repair/rescheduling strategy.
- `run_through`: whether the order cancellation repair/rescheduling chain ran through.
- `feasible`: feasibility flag when available.
- `Cmax_delta`: makespan change when available.
- `SD`: schedule disturbance metric when available.
- `TD`: time deviation metric when available.
- `Y`: weighted selection score when available.
- `error_message`: failure reason when a row does not run through.

## Interpreting Failed Rows

- A nonempty `canceled_order_id` only means random order selection succeeded.
- `run_through = 1` means the order cancellation repair/rescheduling chain ran through.
- `run_through = 0` should be interpreted together with `error_message`.
- If `run_through = 0` and `error_message` is empty, the CSV records a failed-through case but does not yet record a detailed failure reason.

## Current Boundaries

- The `datasets` parameter is available, but current evidence does not support a multi-dataset conclusion.
- Machine failure is not handled in the current order cancellation prototype.
- AGV failure is not handled in the current order cancellation prototype.
- New order insertion is not handled in the current order cancellation prototype.
- Reinforcement learning is not included in the current order cancellation prototype.
- The current prototype does not prove global optimality.
