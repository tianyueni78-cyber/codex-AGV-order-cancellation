# Order Cancellation Large Experiment Plan

## Available Sample Datasets

Current `data_sample/*.fjs` files:

- `data_sample/Mk01.fjs`

Because only one sample dataset is currently available, the recommended large-experiment dataset subset is:

```matlab
datasets = {'data_sample/Mk01.fjs'};
```

## A. Small Check

- `seeds = 1:3`
- `cancelTimes = [5 9]`
- `datasets = {'data_sample/Mk01.fjs'}`
- Total rows: `1 x 3 x 2 = 6`

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
seeds = 1:3;
cancelTimes = [5 9];
datasets = {'data_sample/Mk01.fjs'};
run('scripts/run_random_order_cancellation_batch.m')
```

## B. Medium Acceptance

- `seeds = 1:30`
- `cancelTimes = [5 9 13]`
- `datasets = {'data_sample/Mk01.fjs'}`
- Total rows: `1 x 30 x 3 = 90`

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
seeds = 1:30;
cancelTimes = [5 9 13];
datasets = {'data_sample/Mk01.fjs'};
run('scripts/run_random_order_cancellation_batch.m')
```

## C. Large Experiment

- `seeds = 1:100`
- `cancelTimes = [3 5 7 9 11 13 15]`
- `datasets = {'data_sample/Mk01.fjs'}`
- Total rows: `1 x 100 x 7 = 700`

Run in MATLAB Command Window:

```matlab
cd('D:/CODEX/code_refactor_project/codex-AGV-order-cancellation')
seeds = 1:100;
cancelTimes = [3 5 7 9 11 13 15];
datasets = {'data_sample/Mk01.fjs'};
run('scripts/run_random_order_cancellation_batch.m')
```

## Row Meaning

The total row count is:

```text
dataset_count x seed_count x cancel_time_count
```

Each row is one random order cancellation scenario for one dataset, one seed, and one cancellation time.

## Field Interpretation

- `canceled_order_id` exists: random order selection succeeded.
- `run_through = 1`: the order cancellation repair/rescheduling flow ran through.
- `run_through = 0`: inspect `error_message` for the failure reason.

## Interpretation Boundary

- The large experiment does not prove global optimality.
- The large experiment does not prove general effectiveness across all datasets.
- The large experiment only expands random scenario coverage for code-prototype stability validation.
