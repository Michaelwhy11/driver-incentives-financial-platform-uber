# Data dictionary

All data are synthetic. Final cutoff: March 10, 2026 at 00:00 UTC. Ingestion timestamps use a UTC convention. Service dates: January 5–March 1, 2026.

## Raw deliveries

File: `data/raw/raw_trip_event.csv`.

| Field | Meaning |
|---|---|
| event_id | Unique delivery ID; retries can have separate IDs |
| trip_id | Business key shared by snapshots of one trip |
| version | Source snapshot version |
| cluster_id | Geographic market, 0–47 |
| service_date | Date of completed service |
| ingested_at | When the delivery became visible |
| fare_cents | Full snapshot fare |
| driver_base_cents | Base driver payable |
| refund_cents | Refund in this complete snapshot, not an additive adjustment |
| incentive_cents | Earned incentive |
| variable_cost_cents | Other costs excluding incentive and base driver payable |

`market_assignment.csv` contains cluster_id, pair_id and arm. `synthetic_financial_reference.csv` contains reference market-day revenue, incentive and variable costs in cents. It shares simulated truth with events.

## Processed data

`daily_finance.csv` has one row per service_date and cluster_id. Fields are trips, gross_bookings_cents, revenue_cents, incentive_cents, variable_cost_cents and contribution_cents.

`experiment_cluster.csv` has one row per market with pair, arm and pre/post financial totals in cents. `quarantine.csv` retains the rejected latest snapshot. `reconciliation.csv` contains signed model-minus-reference differences.

## Analysis outputs

| File | Grain and use |
|---|---|
| pair_effects.csv | Pair; treatment change minus control change |
| effect_summary.csv | Metric; approximate paired t interval and standard error |
| financial_bridge.csv | Signed component; contribution is a result, not another cost |
| period_summary.csv | Period × assigned group |
| forecast_backtest.csv | Date × assigned group; predicted and actual outcomes |
| forecast_future.csv | Date × assigned group; actuals blank |
| scenarios.csv | Incentive × assumed growth; dollars per market over 28 days |
| breakeven_thresholds.csv | Incentive; fractional required trip lift |
| power_planning.json | Illustrative independent-pair power assumptions |

Fields ending in `_usd` are dollars. Fractional growth and WAPE use 0.0415 for 4.15%. `trip_lift_cushion_pp` is in percentage points. The Power BI CSV snapshot is under powerbi/data and is a checked-in report snapshot; updated SQL exports must be mapped explicitly.
