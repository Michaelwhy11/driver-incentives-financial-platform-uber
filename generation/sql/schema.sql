-- SIMULATED PRACTICE DATA ONLY. Currency: USD; amounts: integer cents; times: UTC.
PRAGMA foreign_keys=ON;
CREATE TABLE run_config(seed INTEGER, as_of TEXT, simulation_label TEXT);
CREATE TABLE cluster(cluster_id INTEGER PRIMARY KEY, pair_id INTEGER NOT NULL, arm TEXT NOT NULL CHECK(arm IN ('control','treatment')));
CREATE TABLE raw_trip_event(event_id TEXT PRIMARY KEY, trip_id TEXT NOT NULL, version INTEGER NOT NULL, cluster_id INTEGER NOT NULL REFERENCES cluster, service_date TEXT NOT NULL, ingested_at TEXT NOT NULL, fare_cents INTEGER NOT NULL, driver_base_cents INTEGER NOT NULL, refund_cents INTEGER NOT NULL, incentive_cents INTEGER NOT NULL, variable_cost_cents INTEGER NOT NULL);
CREATE TABLE ledger_daily(service_date TEXT, cluster_id INTEGER REFERENCES cluster, revenue_cents INTEGER NOT NULL, incentive_cents INTEGER NOT NULL, variable_cost_cents INTEGER NOT NULL, PRIMARY KEY(service_date,cluster_id));
CREATE INDEX trip_event_lookup ON raw_trip_event(trip_id,version,ingested_at);
