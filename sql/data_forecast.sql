WITH parameters AS (
    -- Use February 22 to test predictions for February 23–March 1.
    SELECT DATE '2026-02-22' AS cutoff_date -- 2026-02-22 for test, 2026-03-01 for forecast
), daily_by_group AS (
SELECT a.service_date, b.arm AS assigned_group, SUM(a.trips) AS trips, SUM(a.revenue_cents) AS revenue_cents, SUM(a.incentive_cents) AS incentive_cents, SUM(a.variable_cost_cents) AS variable_cost_cents, SUM(a.contribution_cents) AS contribution_cents FROM uber_project1.daily_finance AS a JOIN uber_project1.experiment_cluster AS b USING (cluster_id) GROUP BY a.service_date, b.arm
), training AS (
SELECT a.* FROM daily_by_group AS a JOIN parameters AS b ON a.service_date BETWEEN b.cutoff_date - 13 AND b.cutoff_date
), trip_estimates AS (
SELECT assigned_group, EXTRACT(ISODOW FROM service_date)::INTEGER AS weekday, AVG(trips) AS estimated_trips FROM training GROUP BY assigned_group, EXTRACT(ISODOW FROM service_date)::INTEGER
), revenue_per_trip_estimates AS (
SELECT assigned_group, SUM(revenue_cents) / 100.0 / NULLIF(SUM(trips), 0) AS estimated_revenue_per_trip, SUM(incentive_cents) / 100.0 / NULLIF(SUM(trips), 0) AS incentive_per_trip, SUM(variable_cost_cents) / 100.0 / NULLIF(SUM(trips), 0) AS variable_cost_per_trip FROM training GROUP BY assigned_group
), forecast_dates AS (
SELECT a.cutoff_date + b.day_number AS forecast_date FROM parameters AS a CROSS JOIN generate_series(1, 7) AS b(day_number)
), group_forecasts AS (
SELECT a.forecast_date, b.assigned_group, b.estimated_trips, c.estimated_revenue_per_trip, b.estimated_trips * c.estimated_revenue_per_trip AS predicted_revenue_usd, b.estimated_trips * c.incentive_per_trip AS predicted_incentive_usd, b.estimated_trips * c.variable_cost_per_trip AS predicted_variable_cost_usd FROM forecast_dates AS a JOIN trip_estimates AS b ON b.weekday = EXTRACT(ISODOW FROM a.forecast_date)::INTEGER JOIN revenue_per_trip_estimates AS c ON b.assigned_group = c.assigned_group
), daily_forecasts AS (
SELECT forecast_date, SUM(estimated_trips) AS estimated_trips, SUM(predicted_revenue_usd) AS predicted_revenue_usd, SUM(predicted_incentive_usd) AS predicted_incentive_usd, SUM(predicted_variable_cost_usd) AS predicted_variable_cost_usd, SUM(predicted_revenue_usd - predicted_incentive_usd - predicted_variable_cost_usd) AS predicted_contribution_usd FROM group_forecasts GROUP BY forecast_date
), daily_actuals AS (
SELECT service_date, SUM(trips) AS actual_trips, SUM(revenue_cents) / 100.0 AS actual_revenue_usd, SUM(contribution_cents) / 100.0 AS actual_contribution_usd FROM daily_by_group GROUP BY service_date
), evaluation AS (
SELECT a.forecast_date, a.estimated_trips, b.actual_trips, a.predicted_revenue_usd, b.actual_revenue_usd, b.actual_revenue_usd - a.predicted_revenue_usd AS error_usd, ABS(b.actual_revenue_usd - a.predicted_revenue_usd) AS absolute_error_usd, a.predicted_contribution_usd, b.actual_contribution_usd, b.actual_contribution_usd - a.predicted_contribution_usd AS contribution_error_usd, ABS(b.actual_contribution_usd - a.predicted_contribution_usd) AS absolute_contribution_error_usd, a.predicted_incentive_usd
, a.predicted_variable_cost_usd FROM daily_forecasts AS a LEFT JOIN daily_actuals AS b ON a.forecast_date = b.service_date
), estimate_result AS (
SELECT forecast_date, assigned_group, ROUND(estimated_trips, 2) AS estimated_trips, ROUND(estimated_revenue_per_trip, 4) AS estimated_revenue_per_trip_usd, ROUND(predicted_revenue_usd, 2) AS predicted_revenue_usd, ROUND(predicted_revenue_usd - predicted_incentive_usd - predicted_variable_cost_usd, 2) AS predicted_contribution_usd FROM group_forecasts ORDER BY forecast_date, assigned_group
), estimate_diff AS (
SELECT forecast_date, ROUND(estimated_trips, 2) AS estimated_trips, actual_trips, ROUND(actual_trips - estimated_trips, 2) AS trip_error, ROUND(predicted_revenue_usd, 2) AS predicted_revenue_usd, ROUND(actual_revenue_usd, 2) AS actual_revenue_usd, ROUND(predicted_revenue_usd / NULLIF(estimated_trips, 0), 4) AS estimated_revenue_per_trip_usd, ROUND(actual_revenue_usd / NULLIF(actual_trips, 0), 4) AS actual_revenue_per_trip_usd, ROUND(error_usd, 2) AS error_usd, ROUND(absolute_error_usd, 2) AS absolute_error_usd, ROUND(predicted_contribution_usd, 2) AS predicted_contribution_usd, ROUND(actual_contribution_usd, 2) AS actual_contribution_usd, ROUND(predicted_contribution_usd / NULLIF(estimated_trips, 0), 4) AS estimated_contribution_per_trip_usd, ROUND(actual_contribution_usd / NULLIF(actual_trips, 0), 4) AS actual_contribution_per_trip_usd, ROUND(contribution_error_usd, 2) AS contribution_error_usd, ROUND(absolute_contribution_error_usd, 2) AS absolute_contribution_error_usd FROM evaluation ORDER BY forecast_date
), accuracy_table AS (
SELECT COUNT(*) AS forecast_days, COUNT(actual_revenue_usd) AS days_with_actuals, ROUND(AVG(absolute_error_usd), 2) AS rvn_mae_usd, ROUND( 100.0 * SUM(absolute_error_usd) / NULLIF(SUM(ABS(actual_revenue_usd)) FILTER (WHERE predicted_revenue_usd IS NOT NULL), 0), 2) AS rvn_wape_percent, ROUND(AVG(error_usd), 2) AS rvn_mean_error_usd, ROUND(AVG(absolute_contribution_error_usd), 2) AS contribution_mae_usd, ROUND( 100.0 * SUM(absolute_contribution_error_usd) / NULLIF(SUM(ABS(actual_contribution_usd)) FILTER (WHERE predicted_contribution_usd IS NOT NULL), 0), 2) AS contribution_wape_percent, ROUND(AVG(contribution_error_usd), 2) AS mean_contribution_error_usd FROM evaluation
), trip_accuracy AS(
SELECT COUNT(actual_trips) AS evaluated_days, ROUND(AVG(ABS(actual_trips - estimated_trips)), 2) AS trips_mae, ROUND(100.0 * SUM(ABS(actual_trips - estimated_trips)) / NULLIF(SUM(actual_trips) FILTER (WHERE estimated_trips IS NOT NULL), 0), 2) AS trips_wape_percent, ROUND(AVG(actual_trips - estimated_trips), 2) AS mean_trip_error FROM evaluation)
-- MAE: Mean Absolute Error
-- WAPE: Weighted Absolute Percentage Error
SELECT * FROM estimate_result;
