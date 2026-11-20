CREATE TABLE uber_project1.daily_finance AS
WITH row_count_table AS (
SELECT COUNT(*) AS imported_raw_rows FROM uber_project1.raw_trip_event
), parameters AS (
SELECT TIMESTAMP '2026-03-10 00:00:00' AS as_of_utc
), ranked AS (
SELECT a.*, ROW_NUMBER() OVER (PARTITION BY a.trip_id ORDER BY a.version DESC, a.ingested_at DESC, a.event_id DESC) AS rn FROM uber_project1.raw_trip_event a CROSS JOIN parameters b WHERE a.ingested_at <= b.as_of_utc
), latest_snapshot AS (
SELECT * FROM ranked WHERE rn = 1
), validated AS (
SELECT *, (fare_cents < 0 OR driver_base_cents < 0 OR driver_base_cents > fare_cents OR refund_cents < 0 OR refund_cents > fare_cents OR incentive_cents < 0 OR variable_cost_cents < 0) AS is_invalid FROM latest_snapshot
), fact_trip AS (
SELECT *, fare_cents - driver_base_cents - refund_cents AS revenue_cents, fare_cents - driver_base_cents - refund_cents - incentive_cents - variable_cost_cents AS contribution_cents FROM validated WHERE NOT is_invalid
), daily_finance_from_raw AS (
SELECT service_date, cluster_id, COUNT(*) AS trips, SUM(fare_cents)::bigint AS gross_bookings_cents, SUM(revenue_cents)::bigint AS revenue_cents, SUM(incentive_cents)::bigint AS incentive_cents, SUM(variable_cost_cents)::bigint AS variable_cost_cents, SUM(contribution_cents)::bigint AS contribution_cents FROM fact_trip GROUP BY service_date,  cluster_id)
SELECT * FROM daily_finance_from_raw;