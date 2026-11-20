WITH market_totals AS (
SELECT a.cluster_id, b.pair_id, b.arm AS assigned_group, SUM(a.revenue_cents) FILTER (WHERE a.service_date BETWEEN '2026-01-05' AND '2026-02-01') AS baseline_revenue, SUM(a.revenue_cents) FILTER (WHERE a.service_date BETWEEN '2026-02-02' AND '2026-03-01') AS experiment_revenue, SUM(a.contribution_cents) FILTER (WHERE a.service_date BETWEEN '2026-01-05' AND '2026-02-01') AS baseline_contribution, SUM(a.contribution_cents) FILTER (WHERE a.service_date BETWEEN '2026-02-02' AND '2026-03-01') AS experiment_contribution FROM uber_project1.daily_finance AS a JOIN uber_project1.experiment_cluster AS b USING (cluster_id) GROUP BY a.cluster_id, b.pair_id, b.arm
), market_changes AS (
SELECT cluster_id, pair_id, assigned_group, experiment_revenue - baseline_revenue AS revenue_change_cents, experiment_contribution - baseline_contribution AS contribution_change_cents FROM market_totals
), pair_effects AS (
SELECT a.pair_id, a.cluster_id AS treatment_market, b.cluster_id AS control_market, a.revenue_change_cents - b.revenue_change_cents AS revenue_effect_cents, (a.revenue_change_cents - b.revenue_change_cents) / 100.0 AS revenue_effect_usd, a.contribution_change_cents - b.contribution_change_cents AS contribution_effect_cents, (a.contribution_change_cents - b.contribution_change_cents) / 100.0 AS contribution_effect_usd FROM market_changes AS a JOIN market_changes AS b USING (pair_id) WHERE a.assigned_group = 'treatment' AND b.assigned_group = 'control'
), avg_table AS (
SELECT COUNT(*) AS pair_count, ROUND(AVG(revenue_effect_cents) / 100.0, 2) AS average_revenue_effect_usd, ROUND(AVG(contribution_effect_cents) / 100.0, 2) AS average_contribution_effect_usd, COUNT(*) FILTER (WHERE contribution_effect_cents > 0) AS pairs_with_positive_contribution, COUNT(*) FILTER (WHERE contribution_effect_cents < 0) AS pairs_with_negative_contribution FROM pair_effects
), metric_effects AS (
SELECT pair_id, 'revenue' AS metric, revenue_effect_usd AS effect_usd FROM pair_effects UNION ALL SELECT pair_id, 'contribution' AS metric, contribution_effect_usd AS effect_usd FROM pair_effects
), statistics_table AS (
SELECT metric, COUNT(*) AS pair_count, AVG(effect_usd) AS average_effect, STDDEV_SAMP(effect_usd) AS pair_standard_deviation, STDDEV_SAMP(effect_usd) / SQRT(COUNT(*)::NUMERIC) AS standard_error FROM metric_effects GROUP BY metric
)

SELECT metric, pair_count, ROUND(average_effect, 2) AS average_effect_usd, ROUND(pair_standard_deviation, 2) AS pair_stddev_usd, ROUND(standard_error, 2) AS standard_error_usd,
-- 2.068657610 is the 95% t critical value for 23 degrees of freedom: 24 pairs minus 1.
(CASE WHEN pair_count = 24 THEN ROUND(average_effect - 2.068657610 * standard_error, 2) END) AS ci_95_lower_usd, (CASE WHEN pair_count = 24 THEN ROUND(average_effect + 2.068657610 * standard_error, 2) END) AS ci_95_upper_usd FROM statistics_table ORDER BY metric;

-- Revenue: the confidence interval is entirely above zero, supporting a positive revenue effect under this simulated design.
-- Contribution: the confidence interval is entirely below zero, supporting a negative contribution effect. Its upper endpoint is close to zero, so this conclusion is less precise.
-- Under our chosen simulated assumptions, higher incentives increased revenue but reduced contribution after costs
