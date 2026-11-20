SELECT current_database(), current_user;
CREATE SCHEMA IF NOT EXISTS uber_project1;
-- raw_trip_event
CREATE TABLE IF NOT EXISTS uber_project1.raw_trip_event (event_id text PRIMARY KEY,
 trip_id text NOT NULL, version integer NOT NULL, cluster_id integer NOT NULL, service_date date NOT NULL, ingested_at timestamp without time zone NOT NULL, fare_cents bigint NOT NULL,
 driver_base_cents bigint NOT NULL, refund_cents bigint NOT NULL, incentive_cents bigint NOT NULL, variable_cost_cents bigint NOT NULL);
CREATE INDEX IF NOT EXISTS raw_trip_event_latest_idx ON uber_project1.raw_trip_event(trip_id, version DESC, ingested_at DESC, event_id DESC);
-- general view run after raw_to_daily_finance.sql
SELECT COUNT(*) AS row_count, MIN(service_date) AS first_date, MAX(service_date) AS last_date, COUNT(DISTINCT service_date) AS distinct_days, COUNT(DISTINCT cluster_id) AS markets FROM uber_project1.daily_finance;
-- head view
SELECT service_date, cluster_id, trips, ROUND(gross_bookings_cents / 100.0, 2) AS gross_bookings_usd, ROUND(revenue_cents / 100.0, 2) AS revenue_usd, ROUND(incentive_cents / 100.0, 2) AS incentive_usd, ROUND(variable_cost_cents / 100.0, 2) AS variable_cost_usd, ROUND(contribution_cents / 100.0, 2) AS contribution_usd FROM uber_project1.daily_finance ORDER BY service_date, cluster_id LIMIT 5;
-- duplicate check
SELECT service_date, cluster_id, COUNT(*) AS row_count FROM uber_project1.daily_finance GROUP BY service_date, cluster_id HAVING COUNT(*) > 1;
-- null check
SELECT COUNT(*) AS rows_with_missing_values FROM uber_project1.daily_finance WHERE service_date IS NULL OR cluster_id IS NULL OR trips IS NULL OR gross_bookings_cents IS NULL OR revenue_cents IS NULL OR incentive_cents IS NULL OR variable_cost_cents IS NULL OR contribution_cents IS NULL;
-- contribution check
SELECT service_date, cluster_id, revenue_cents, incentive_cents, variable_cost_cents, contribution_cents, revenue_cents - incentive_cents - variable_cost_cents AS expected_contribution_cents FROM uber_project1.daily_finance WHERE revenue_cents - incentive_cents - variable_cost_cents <> contribution_cents;
-- total check
SELECT SUM(trips) AS total_trips, ROUND(SUM(gross_bookings_cents) / 100.0, 2) AS gross_bookings_usd, ROUND(SUM(revenue_cents) / 100.0, 2) AS revenue_usd, ROUND(SUM(incentive_cents) / 100.0, 2) AS incentives_usd, ROUND(SUM(variable_cost_cents) / 100.0, 2) AS variable_cost_usd, ROUND(SUM(contribution_cents) / 100.0, 2) AS contribution_usd
FROM uber_project1.daily_finance;
-- experiment_cluster
CREATE TABLE uber_project1.experiment_cluster (cluster_id INTEGER, pair_id INTEGER, arm TEXT, pre_revenue BIGINT, post_revenue BIGINT, pre_contribution BIGINT, post_contribution BIGINT
);
-- base check
SELECT arm, COUNT(*) AS markets, COUNT(DISTINCT pair_id) AS pairs FROM uber_project1.experiment_cluster GROUP BY arm;
-- duplicate check
SELECT cluster_id, COUNT(*) AS occurrences FROM uber_project1.experiment_cluster GROUP BY cluster_id HAVING COUNT(*) > 1;
-- market check
SELECT DISTINCT a.cluster_id FROM uber_project1.daily_finance AS a LEFT JOIN uber_project1.experiment_cluster AS b USING (cluster_id) WHERE b.cluster_id IS NULL;
-- baseline define
SELECT a.service_date, a.cluster_id, b.pair_id, b.arm, (CASE WHEN a.service_date < DATE '2026-02-02' THEN 'baseline' ELSE 'experiment' END) AS period,a.trips, ROUND(a.revenue_cents / 100.0, 2) AS revenue_usd, ROUND(a.contribution_cents / 100.0, 2) AS contribution_usd FROM uber_project1.daily_finance AS a JOIN uber_project1.experiment_cluster AS b USING(cluster_id) ORDER BY a.service_date, a.cluster_id LIMIT 10;
-- reconciliation
CREATE TABLE uber_project1.reconciliation (service_date DATE, cluster_id INTEGER, revenue_delta_cents BIGINT, incentive_delta_cents BIGINT, cost_delta_cents BIGINT);
-- quarantine
CREATE TABLE uber_project1.quarantine (event_id TEXT, trip_id TEXT, version INTEGER, cluster_id INTEGER, service_date DATE, ingested_at TIMESTAMP, fare_cents BIGINT, driver_base_cents BIGINT, refund_cents BIGINT, incentive_cents BIGINT, variable_cost_cents BIGINT, rn INTEGER);
