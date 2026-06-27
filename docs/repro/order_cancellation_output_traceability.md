# Order Cancellation Output Traceability

## Result Files

Known batch random order cancellation result files:

```text
outputs/batch_random_order_cancellation/20260627_131427/batch_random_order_cancellation.csv
outputs/batch_random_order_cancellation/20260627_131448/batch_random_order_cancellation.csv
outputs/batch_random_order_cancellation/20260627_131510/batch_random_order_cancellation.csv
```

## Run Configuration

### Small Check

- `output_csv`: `outputs/batch_random_order_cancellation/20260627_131427/batch_random_order_cancellation.csv`
- `dataset`: `data_sample/Mk01.fjs`
- `seeds`: `1:3`
- `cancelTimes`: `[5 9]`
- `dataset_count`: `1`
- `seed_count`: `3`
- `cancel_time_count`: `2`
- `row_count`: `6`

### Medium Acceptance

- `output_csv`: `outputs/batch_random_order_cancellation/20260627_131448/batch_random_order_cancellation.csv`
- `dataset`: `data_sample/Mk01.fjs`
- `seeds`: `1:30`
- `cancelTimes`: `[5 9 13]`
- `dataset_count`: `1`
- `seed_count`: `30`
- `cancel_time_count`: `3`
- `row_count`: `90`
- `run_through = 1`: `61 / 90`
- `selected_strategy`: `local_repair = 61`, blank = `29`

### Large Experiment

- `output_csv`: `outputs/batch_random_order_cancellation/20260627_131510/batch_random_order_cancellation.csv`
- `dataset`: `data_sample/Mk01.fjs`
- `seeds`: `1:100`
- `cancelTimes`: `[3 5 7 9 11 13 15]`
- `dataset_count`: `1`
- `seed_count`: `100`
- `cancel_time_count`: `7`
- `row_count`: `700`
- `run_through = 1`: `358 / 700`
- `selected_strategy`: `local_repair = 358`, blank = `342`
- `error_message`: blank for all rows in the checked CSV

The single demo run already observed:

- `seed`: `42`
- `cancel.job_id`: `2`
- `cancel.cancel_time`: `9`
- `selected_strategy`: `local_repair`
- `run_through`: `1`

## Row Meaning

Each CSV row represents one random order cancellation scenario:

```text
dataset x seed x cancel_time
```

For each row, the code randomly selects one cancellable order at the given cancellation time, then sends that cancellation event into the existing order cancellation repair/rescheduling chain.

## Key Fields

- `canceled_order_id` / `cancel_job_id`: randomly selected cancelled order.
- `selected_strategy`: selected repair/rescheduling strategy.
- `run_through`: whether the scenario fully entered and ran through the order cancellation repair/rescheduling chain.
- `error_message`: failure reason when a row records one.
- `Cmax_delta`: makespan change, if available.
- `SD`: schedule disturbance metric, if available.
- `TD`: time deviation metric, if available.
- `Y`: strategy evaluation/selection score, if available.

Important interpretation:

- A nonempty `canceled_order_id` means random order selection succeeded.
- `run_through = 1` means the order cancellation repair/rescheduling chain ran through.
- `run_through = 0` must be checked with `error_message`; in the current large CSV, failed-through rows have blank `error_message`, so detailed failure reasons remain to be improved in the logging.

## Supported Claims

- The current code supports a random order cancellation entry.
- The current code supports batch result generation over multiple seeds and cancellation times.
- The current code supports CSV output for result traceability.
- The current outputs can be used as reproducibility evidence for an order cancellation intelligent scheduling prototype.

## Unsupported Claims

- These results do not prove global optimality.
- These results do not prove stable effectiveness across all datasets.
- These results do not prove superiority over all baselines.
- These results do not cover machine failure.
- These results do not cover AGV failure.
- These results do not cover new order insertion.
- These results do not include reinforcement learning.

## Suggested Next Enhancements

- Add more datasets.
- Add more cancellation times.
- Add more seeds.
- Add baseline comparisons.
- Add summary statistics for success rate, average metrics, and failure reasons.
