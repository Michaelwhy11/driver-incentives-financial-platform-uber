-- Combine daily financial records with market assignments.
WITH daily_table AS (
SELECT a.*, b.arm AS assigned_group, (CASE WHEN a.service_date < DATE '2026-02-02' THEN 'baseline' ELSE 'experiment' END) AS period FROM uber_project1.daily_finance AS a JOIN uber_project1.experiment_cluster AS b USING(cluster_id)
), data_table AS (
SELECT period, assigned_group, COUNT(*) AS market_days, COUNT(DISTINCT cluster_id) AS markets, SUM(trips) AS trips, ROUND(SUM(revenue_cents) / 100.0, 2) AS revenue_usd, ROUND(SUM(incentive_cents) / 100.0, 2) AS incentives_usd, ROUND(SUM(variable_cost_cents) / 100.0, 2) AS variable_cost_usd, ROUND(SUM(contribution_cents) / 100.0, 2) AS contribution_usd FROM daily_table GROUP BY period, assigned_group ORDER BY period, assigned_group
), group_totals AS (
SELECT assigned_group, period, SUM(revenue_cents) AS revenue_cents, SUM(contribution_cents) AS contribution_cents FROM daily_table GROUP BY assigned_group, period
), metrics AS (
SELECT assigned_group, period, 'revenue' AS metric, revenue_cents AS amount_cents FROM group_totals UNION ALL SELECT assigned_group, period, 'contribution' AS metric, contribution_cents AS amount_cents FROM group_totals
), comparison AS (
SELECT metric, SUM(amount_cents) FILTER (WHERE assigned_group = 'treatment' AND period = 'baseline') AS treatment_baseline, SUM(amount_cents) FILTER (WHERE assigned_group = 'treatment' AND period = 'experiment') AS treatment_experiment, SUM(amount_cents) FILTER (WHERE assigned_group = 'control' AND period = 'baseline') AS control_baseline, SUM(amount_cents) FILTER ( WHERE assigned_group = 'control' AND period = 'experiment') AS control_experiment FROM metrics GROUP BY metric
), changes AS (
SELECT *, treatment_experiment - treatment_baseline AS treatment_change, control_experiment - control_baseline AS control_change FROM comparison
), diff_table AS (
SELECT metric, ROUND(treatment_baseline / 100.0, 2) AS treatment_baseline_usd, ROUND(treatment_experiment / 100.0, 2) AS treatment_experiment_usd, ROUND(treatment_change / 100.0, 2) AS treatment_change_usd, ROUND(control_baseline / 100.0, 2) AS control_baseline_usd, ROUND(control_experiment / 100.0, 2) AS control_experiment_usd, ROUND(control_change / 100.0, 2) AS control_change_usd, ROUND((treatment_change - control_change) / 100.0, 2) AS difference_in_changes_usd FROM changes ORDER BY metric)
SELECT * FROM data_table;
