# FJSP-AGV Order Cancellation Rescheduling

This repository studies dynamic rescheduling after order cancellation on top of the
original `codex-AGV` FJSP-AGV scheduling code.

The first research target is intentionally narrow: start from an existing normal
FJSP-AGV schedule, cancel one order at a known time, repair or rebuild the
remaining schedule, and compare efficiency improvement against schedule
disruption.

## 1. Problem Scope

Order cancellation is treated as a task-set change problem, not as a machine
availability problem.

In scope for the first stage:

1. Use the original `codex-AGV` data, decoding, AGV, energy, and NSGA-II code as
   the base implementation.
2. Model one order cancellation event with known `cancel_time`.
3. Freeze completed work before the cancellation time.
4. Remove the cancelled order's unfinished operations and related AGV tasks.
5. Generate candidate reschedules for the remaining orders.
6. Evaluate makespan, total energy, and disruption to the old schedule.

Out of scope for the first stage:

1. Machine breakdown or machine repair windows.
2. Multiple cancellation events.
3. New order insertion.
4. AGV failure.
5. Stochastic processing time or uncertain cancellation time.
6. Proof of global optimality.

Machine-failure work should remain separate. It may become a later combined
multi-disturbance framework, but this project first isolates order cancellation.

## 2. Literature Inspiration

This project borrows ideas from rescheduling literature, while adapting them to
FJSP-AGV order cancellation.

1. Rener, Salassa, and T'kindt, "Single machine rescheduling for new orders:
   properties and complexity results" (arXiv:2307.14876).

   Useful idea: after a dynamic event, the new schedule should not only optimize
   the production objective, but also control disruption to the old jobs. The
   paper uses completion-time deviation constraints for old jobs. For order
   cancellation, the analogous idea is to measure completion-time deviation of
   the remaining non-cancelled orders.

2. Tang et al., "Deep Reinforcement Learning for Flexible Job Shop Scheduling
   with Random Job Arrivals" (arXiv:2605.22773).

   Useful idea: dynamic scheduling can be modeled as an event-triggered process.
   This project does not use reinforcement learning in the first stage, but keeps
   the event-triggered structure: cancellation event, state extraction, candidate
   generation, evaluation, and selection.

## 3. Scheduling Thought

The planned research chain is:

```text
normal FJSP-AGV schedule
  -> order cancellation event
  -> cancellation-time state extraction
  -> local repair candidate
  -> complete rescheduling candidate
  -> metric calculation
  -> final strategy selection
```

Two candidate strategies are planned.

### 3.1 Local Repair

Local repair keeps the original plan as much as possible:

1. Remove unfinished operations of the cancelled order.
2. Remove related unfinished AGV transport tasks.
3. Keep remaining orders' operation order, machine choices, and AGV choices when
   feasible.
4. Compress idle time or left-shift remaining tasks only when constraints remain
   valid.

This strategy prioritizes stability and low disruption.

### 3.2 Complete Rescheduling

Complete rescheduling freezes executed tasks and re-optimizes the remaining
unfinished operations of non-cancelled orders.

The first implementation should reuse the original independent NSGA-II,
encoding, decoding, AGV, and evaluation layers where possible.

This strategy may improve final completion time and energy, but can change more
machine assignments and task timings.

## 4. Algorithm Plan

The first algorithmic baseline is the existing independent NSGA-II search from
`codex-AGV`.

Initial objectives:

1. Final unloading completion time.
2. Total energy.

Additional rescheduling metrics:

```text
Cmax_delta = candidate final unloading time - original final unloading time
SD         = number of machine-assignment changes among remaining operations
TD         = total completion-time deviation of remaining orders
Y          = omega1*Cmax_delta + omega2*SD + omega3*TD
```

`TD` is the main borrowed idea from the new-order rescheduling paper: dynamic
rescheduling should control how much the old plan changes. Here, "old jobs" map
to remaining non-cancelled orders.

The first version does not claim global optimality. It should report the best
candidate found under the configured population, generation count, seed, and
weights.

## 5. Work Plan

### Stage A: Source Migration and Baseline Understanding

Goal: preserve the original scheduling baseline and identify the normal schedule
call chain.

Verification:

1. Source directories from `codex-AGV` are present.
2. A source-code map documents data, encoding, decoding, search, evaluation,
   metrics, visualization, scripts, tests, and raw baseline code.
3. No order-cancellation algorithm is added yet.

### Stage B: Order Cancellation Event and State Extraction

Goal: define a minimal cancellation event and extract schedule state at
`cancel_time`.

Planned event fields:

```matlab
cancel.job_id
cancel.cancel_time
cancel.policy
```

First policy:

```text
cancel_unstarted_operations_only
```

Verification:

1. Completed, processing, and unstarted operations can be identified.
2. Cancelled-order unfinished operations can be listed.
3. A smoke test runs on sample data.

### Stage C: Local Repair Candidate

Goal: remove cancelled unfinished work and build a feasible local repair schedule.

Verification:

1. Cancelled unfinished operations do not appear in the candidate.
2. Remaining operations respect job order.
3. Machine and AGV time conflicts are rejected.

### Stage D: Complete Rescheduling Candidate

Goal: reuse the independent decoding/search layers to reschedule remaining
unfinished operations.

Verification:

1. Frozen tasks are preserved.
2. Cancelled unfinished tasks are excluded.
3. Remaining tasks are decoded into a feasible FJSP-AGV schedule.

### Stage E: Evaluation and Strategy Selection

Goal: compare local repair and complete rescheduling.

Verification:

1. `Cmax_delta`, `SD`, `TD`, energy, and `Y` are computed.
2. The selected strategy is the candidate with smaller `Y`.
3. Results are written under `outputs/`.

### Stage F: Small Experiments

Goal: run a small set of cancellation scenarios.

Minimum scenarios:

1. Early cancellation.
2. Middle cancellation.
3. Late cancellation.

Verification:

1. Each scenario reports both candidate strategies.
2. Each scenario passes schedule constraint checks.
3. Multi-seed results are summarized before making research claims.

## 6. Repository Layout

```text
raw_code/       Original archived code from codex-AGV. Read-only baseline.
src/            Refactored source code migrated from codex-AGV.
configs/        MATLAB configuration files.
scripts/        Reproducible run entries.
tests/          Lightweight tests and static checks.
data_sample/    Minimal sample data.
docs/           Source maps, plans, and reproduction notes.
outputs/        Generated outputs and logs. Not committed.
```

See `docs/00_system_overview/source_code_migration_map.md` for the migrated
source-code map.

## 7. Agent Rules

Use `AGENTS.md` as the working contract for this repository.

Core rules:

1. Do not modify `raw_code/`.
2. Do one small task at a time.
3. Prefer static analysis before MATLAB runs.
4. Ask before running MATLAB, launching experiments, or generating outputs.
5. Keep machine-failure code and order-cancellation code separate.
6. Preserve reproducibility through configs, scripts, tests, and outputs.

## 8. Current Status

Current repository status:

```text
Stage A started.
Original codex-AGV source structure has been migrated.
Order-cancellation algorithms have not been implemented yet.
```

