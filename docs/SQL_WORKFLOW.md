# PostgreSQL workflow

The analytical path is CSV import followed by the queries in sql/. All data are simulated. SQL uses schema uber_project1. Generation internals under generation/sql use SQLite and are not run in PostgreSQL.

## Create tables and import CSVs

Open sql/data_import.sql in pgAdmin Query Tool for a database you control. Select statements by stage rather than executing the entire file at once. The file interleaves creation statements and checks that require data to be present.

1. Run CREATE SCHEMA and the raw_trip_event CREATE TABLE / CREATE INDEX statements.
2. Import data/raw/raw_trip_event.csv into uber_project1.raw_trip_event using pgAdmin Import/Export Data, CSV format, Header Yes, delimiter comma and UTF8 encoding.
3. Run the CREATE TABLE statements for experiment_cluster, reconciliation and quarantine in data_import.sql.
4. Import the corresponding CSVs below into those empty tables. Retain the CSV column order.
5. Run sql/raw_to_daily_finance.sql to create daily_finance from raw snapshots. Do not also import daily_finance.csv into this table; use that CSV as the reference result. The CREATE TABLE statement is a first-run operation, not an automatic refresh or upsert.
6. Return to data_import.sql and run the SELECT checks. Expected totals: 63,623 trips, revenue $419,396.63 and contribution $306,872.43 across 2,688 market-day rows.

| CSV | PostgreSQL table |
|---|---|
| data/raw/raw_trip_event.csv | uber_project1.raw_trip_event |
| data/processed/experiment_cluster.csv | uber_project1.experiment_cluster |
| data/processed/reconciliation.csv | uber_project1.reconciliation |
| data/processed/quarantine.csv | uber_project1.quarantine |

If daily_finance already exists, inspect or use a fresh project database rather than blindly rerunning CREATE TABLE or dropping dependencies. The raw query creates a persistent snapshot table. Later source changes do not refresh it automatically.

## Run the analysis queries

- data_process.sql: the final SELECT returns period-by-group totals. To view the difference-in-changes summary instead, replace only the final SELECT with SELECT * FROM diff_table; and run the whole CTE statement.
- test_result.sql: returns the paired revenue and contribution estimates with standard errors and approximate t intervals. Expected averages: +$536.08 and -$103.37 per market over 28 days.
- reason_check.sql: returns the signed financial bridge. Expected bridge_difference_usd is zero.
- data_reconciliation.sql: checks the imported discrepancy report, missing values, duplicated keys and market-day coverage. It inspects a processed simulation output rather than independently recreating a financial ledger.
- data_quarantine.sql: displays the imported invalid fixture and its failed rules. Expected: one rejected record, three rule failures. Daily finance excludes it.
- data_forecast.sql: the final SELECT returns estimate_result. With cutoff February 22, it evaluates the February 23–March 1 holdout. Replace the final SELECT with SELECT * FROM accuracy_table; to view MAE/WAPE, SELECT * FROM estimate_diff; for daily errors, or SELECT * FROM trip_accuracy; for volume accuracy. Run the entire CTE statement after each selection change. With cutoff March 1, the next seven days have no actuals and cannot have measured holdout accuracy.
- optimize_strategy.sql: returns nine scenarios, incremental contribution and the rounded minimum trip-growth threshold. The $0.60 threshold is approximately 4.15%, a required response under fixed unit economics.

The project retains these original SQL filenames and query logic. Two files receive only a terminal semicolon for standalone execution in the publication copy. The excluded legacy SQLite analysis.sql/models.sql/schema.sql are not part of the PostgreSQL workflow; the generator internally retains schema and model definitions under generation/sql/.

## Reporting

The Power BI CSV files, dashboard and final presentation are checked-in snapshots. Export and map new SQL outputs deliberately before replacing those report inputs. A change to the database does not automatically update the packaged HTML, presentation or report CSVs.
