# Order Cancellation Delivery Checklist

## Delivery Goal

- Provide an intelligent scheduling code prototype for order cancellation.
- Support a single random order cancellation demo.
- Support batch random order cancellation.
- Support controllable `seed`, `cancel_time`, and `dataset`.
- Support CSV output and result traceability.

## Core Code Entries

- `scripts/run_random_order_cancellation_demo.m`
- `scripts/run_random_order_cancellation_batch.m`
- `src/cancellation/build_order_cancellation_scenarios.m`
- `src/cancellation/run_order_cancellation_library_scenario.m`

## Reproduction Documents

- `docs/repro/order_cancellation_repro_guide.md`
- `docs/repro/order_cancellation_output_traceability.md`
- `docs/repro/order_cancellation_large_experiment_plan.md`
- `docs/repro/order_cancellation_large_experiment_results.md`

## Existing Output Example

- `outputs/batch_random_order_cancellation/20260627_131448/batch_random_order_cancellation.csv`
- `dataset_count = 1`
- `seed_count = 30`
- `cancel_time_count = 3`
- `row_count = 90`

Large batch output:

- `outputs/batch_random_order_cancellation/20260627_131510/batch_random_order_cancellation.csv`
- `dataset_count = 1`
- `seed_count = 100`
- `cancel_time_count = 7`
- `row_count = 700`

## Acceptance Checklist

- Demo can output `canceled_order_id` / `cancel_job_id`.
- Demo can output `selected_strategy`.
- Demo can output `run_through`.
- Batch run can generate CSV.
- Batch row count equals `dataset_count x seed_count x cancel_time_count`.
- CSV can trace `dataset`, `seed`, and `cancel_time`.
- `run_through = 1` means the full order cancellation repair/rescheduling flow ran through.
- `run_through = 0` must be interpreted together with `error_message`.
- `raw_code/` is not modified.
- `<b0></b0>` is not modified.

## Current Boundaries

- This is not a complete paper-level experimental system.
- Multi-dataset support is currently a parameter entry, not a multi-dataset conclusion.
- Machine failure is not handled.
- AGV failure is not handled.
- New order insertion is not handled.
- Reinforcement learning is not included.
- Global optimality is not proven.

## Suggested Next Enhancements

- Add batch results for more datasets.
- Add more cancellation times.
- Add more seeds.
- Add baseline comparisons.
- Add success-rate statistics.
- Add failure-reason statistics.
- Add metric summary tables.
