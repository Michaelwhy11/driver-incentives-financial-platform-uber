WITH market_changes AS (
SELECT a.cluster_id, b.pair_id, b.arm AS assigned_group,
-- +1 for experiment days; -1 for baseline days.
SUM(a.revenue_cents * (CASE WHEN a.service_date >= '2026-02-02' THEN 1 ELSE -1 END)) AS revenue_change_cents, SUM(a.incentive_cents * (CASE WHEN a.service_date >= '2026-02-02' THEN 1 ELSE -1 END)) AS incentive_change_cents, SUM(a.variable_cost_cents * (CASE WHEN a.service_date >= '2026-02-02' THEN 1 ELSE -1 END)) AS variable_cost_change_cents, SUM(a.contribution_cents * (CASE WHEN a.service_date >= '2026-02-02' THEN 1 ELSE -1 END)) AS contribution_change_cents FROM uber_project1.daily_finance AS a JOIN uber_project1.experiment_cluster AS b USING(cluster_id) WHERE a.service_date BETWEEN DATE '2026-01-05' AND DATE '2026-03-01' GROUP BY a.cluster_id, b.pair_id, b.arm
), pair_effects AS (
SELECT a.pair_id, a.revenue_change_cents - b.revenue_change_cents AS revenue_effect_cents, a.incentive_change_cents - b.incentive_change_cents AS incentive_effect_cents, a.variable_cost_change_cents - b.variable_cost_change_cents AS variable_cost_effect_cents, a.contribution_change_cents - b.contribution_change_cents AS contribution_effect_cents FROM market_changes AS a JOIN market_changes AS b USING(pair_id) WHERE a.assigned_group = 'treatment' AND b.assigned_group = 'control'
), average_effects AS (
SELECT COUNT(*) AS pair_count, AVG(revenue_effect_cents) / 100.0 AS revenue_effect_usd, AVG(incentive_effect_cents) / 100.0 AS incentive_effect_usd, AVG(variable_cost_effect_cents) / 100.0 AS variable_cost_effect_usd, AVG(contribution_effect_cents) / 100.0 AS contribution_effect_usd FROM pair_effects
)

SELECT pair_count, ROUND(revenue_effect_usd, 2) AS revenue_effect_usd, ROUND(incentive_effect_usd, 2) AS incentive_effect_usd, ROUND(variable_cost_effect_usd, 2) AS variable_cost_effect_usd, ROUND(contribution_effect_usd, 2) AS contribution_effect_usd, ROUND(
revenue_effect_usd - incentive_effect_usd - variable_cost_effect_usd - contribution_effect_usd,
2) AS bridge_difference_usd FROM average_effects;
-- The added modeled revenue did not cover the added incentive expense and other variable costs