-- Deterministic replay: deduplicate at business key + latest version, then validate.
CREATE VIEW ranked_trip AS
SELECT e.*, 1 AS rn FROM raw_trip_event e
WHERE e.ingested_at <= (SELECT as_of FROM run_config)
AND NOT EXISTS (SELECT 1 FROM raw_trip_event newer
 WHERE newer.trip_id=e.trip_id AND newer.ingested_at <= (SELECT as_of FROM run_config)
 AND (newer.version>e.version OR (newer.version=e.version AND newer.ingested_at>e.ingested_at)
 OR (newer.version=e.version AND newer.ingested_at=e.ingested_at AND newer.event_id>e.event_id)));
CREATE VIEW quarantine AS SELECT * FROM ranked_trip WHERE rn=1 AND
(fare_cents<0 OR driver_base_cents<0 OR driver_base_cents>fare_cents OR refund_cents<0 OR refund_cents>fare_cents OR incentive_cents<0 OR variable_cost_cents<0);
CREATE VIEW fact_trip AS SELECT *, fare_cents-driver_base_cents-refund_cents AS revenue_cents,
 fare_cents-driver_base_cents-refund_cents-incentive_cents-variable_cost_cents AS contribution_cents
FROM ranked_trip WHERE rn=1 AND NOT EXISTS(SELECT 1 FROM quarantine q WHERE q.event_id=ranked_trip.event_id);
CREATE VIEW daily_finance AS
SELECT service_date,cluster_id,COUNT(*) trips,SUM(fare_cents) gross_bookings_cents,
 SUM(revenue_cents) revenue_cents,SUM(incentive_cents) incentive_cents,
 SUM(variable_cost_cents) variable_cost_cents,SUM(contribution_cents) contribution_cents
FROM fact_trip GROUP BY service_date,cluster_id;
-- Ledger-driven join plus explicit analytical-only keys prevents hidden missing groups.
CREATE VIEW reconciliation AS
SELECT l.service_date,l.cluster_id,COALESCE(f.revenue_cents,0)-l.revenue_cents revenue_delta_cents,
 COALESCE(f.incentive_cents,0)-l.incentive_cents incentive_delta_cents,
 COALESCE(f.variable_cost_cents,0)-l.variable_cost_cents cost_delta_cents
FROM ledger_daily l LEFT JOIN daily_finance f USING(service_date,cluster_id)
UNION ALL SELECT f.service_date,f.cluster_id,f.revenue_cents,f.incentive_cents,f.variable_cost_cents
FROM daily_finance f LEFT JOIN ledger_daily l USING(service_date,cluster_id) WHERE l.cluster_id IS NULL;
CREATE VIEW experiment_cluster AS
SELECT c.cluster_id,c.pair_id,c.arm,
 SUM(CASE WHEN f.service_date<'2026-02-02' THEN f.revenue_cents ELSE 0 END) pre_revenue,
 SUM(CASE WHEN f.service_date>='2026-02-02' THEN f.revenue_cents ELSE 0 END) post_revenue,
 SUM(CASE WHEN f.service_date<'2026-02-02' THEN f.contribution_cents ELSE 0 END) pre_contribution,
 SUM(CASE WHEN f.service_date>='2026-02-02' THEN f.contribution_cents ELSE 0 END) post_contribution
FROM cluster c JOIN daily_finance f USING(cluster_id) GROUP BY c.cluster_id,c.pair_id,c.arm;
