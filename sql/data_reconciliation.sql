-- Missing values
SELECT COUNT(*) AS row_count, COUNT(*) FILTER (WHERE service_date IS NULL OR cluster_id IS NULL OR revenue_delta_cents IS NULL OR incentive_delta_cents IS NULL OR cost_delta_cents IS NULL) AS rows_with_missing_values FROM uber_project1.reconciliation;
-- duplicate market days
SELECT service_date, cluster_id, COUNT(*) AS occurrences FROM uber_project1.reconciliation GROUP BY service_date, cluster_id HAVING COUNT(*) > 1;
-- Financials discrepancies
SELECT * FROM uber_project1.reconciliation WHERE revenue_delta_cents <> 0 OR incentive_delta_cents <> 0 OR cost_delta_cents <> 0 ORDER BY service_date, cluster_id;
-- Discrepancies(if available)
SELECT COUNT(*) AS market_days, COUNT(*) FILTER (WHERE revenue_delta_cents <> 0 OR incentive_delta_cents <> 0 OR cost_delta_cents <> 0) AS market_days_with_discrepancies, SUM(ABS(revenue_delta_cents)) / 100.0 AS absolute_revenue_discrepancy_usd, SUM(ABS(incentive_delta_cents)) / 100.0 AS absolute_incentive_discrepancy_usd, SUM(ABS(cost_delta_cents)) / 100.0 AS absolute_cost_discrepancy_usd FROM uber_project1.reconciliation;
-- market days missing
SELECT COALESCE(a.service_date, b.service_date) AS service_date, COALESCE(a.cluster_id, b.cluster_id) AS cluster_id, (CASE WHEN a.cluster_id IS NULL THEN 'Missing from daily_finance' WHEN b.cluster_id IS NULL THEN 'Missing from reconciliation' END) AS issue FROM uber_project1.daily_finance AS a FULL OUTER JOIN uber_project1.reconciliation AS b ON a.service_date = b.service_date AND a.cluster_id = b.cluster_id WHERE a.cluster_id IS NULL OR b.cluster_id IS NULL;