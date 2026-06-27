# Order Cancellation Large Experiment Results

## Evidence Scope

This document records existing outputs for the order cancellation intelligent scheduling code prototype. It is for code reproduction and project acceptance, not for claiming global optimality or broad dataset-level effectiveness.

## Output CSV

```text
outputs/batch_random_order_cancellation/20260627_131510/batch_random_order_cancellation.csv
```

## Run Configuration

- `dataset`: `data_sample/Mk01.fjs`
- `dataset_count`: `1`
- `seeds`: `1:100`
- `seed_count`: `100`
- `cancelTimes`: `[3 5 7 9 11 13 15]`
- `cancel_time_count`: `7`
- `row_count`: `700`

Each row is one random order cancellation scenario:

```text
dataset x seed x cancel_time
```

## Summary From Existing CSV

- `run_through = 1`: `358 / 700`
- `run_through` success rate: `51.14%`
- `feasible = 1`: `358 / 700`
- `selected_strategy` distribution:
  - `local_repair`: `358`
  - blank: `342`
- `error_message` distribution:
  - blank: `700`

## Run-Through By Cancel Time

| cancel_time | rows | run_through=1 | run_through rate |
| --- | ---: | ---: | ---: |
| 3 | 100 | 60 | 60% |
| 5 | 100 | 69 | 69% |
| 7 | 100 | 69 | 69% |
| 9 | 100 | 100 | 100% |
| 11 | 100 | 31 | 31% |
| 13 | 100 | 29 | 29% |
| 15 | 100 | 0 | 0% |

## Field Interpretation

- `canceled_order_id` exists: random order selection succeeded.
- `selected_strategy`: strategy selected by the current order cancellation evaluation flow.
- `run_through = 1`: the order cancellation repair/rescheduling chain ran through.
- `run_through = 0`: the row did not run through; inspect `error_message` if populated.
- `error_message`: failure reason when recorded. In this CSV, the field is blank for all rows, so detailed failure causes are not yet available from the CSV alone.
- `Cmax_delta`, `SD`, `TD`, `Y`: strategy evaluation/selection metrics when available.

## Supported Claims

- The code can generate random order cancellation scenarios.
- The code can run batch checks over multiple seeds and cancellation times.
- The code can write CSV outputs that are traceable to dataset, seed, and cancellation time.
- The existing large batch output can support code-prototype stability inspection for `data_sample/Mk01.fjs`.

## Unsupported Claims

- This output does not prove global optimality.
- This output does not prove stable effectiveness across all datasets.
- This output does not prove superiority over all baselines.
- This output does not cover machine failure.
- This output does not cover AGV failure.
- This output does not cover new order insertion.
- This output does not include reinforcement learning.

## Follow-Up Enhancements

- Add more datasets.
- Add more cancellation times if needed.
- Add more seeds if needed.
- Add baseline comparisons.
- Add explicit failure-reason logging for `run_through = 0`.
- Add metric summary tables for successful rows.
