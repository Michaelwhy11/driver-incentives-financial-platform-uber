# Report evidence

These checked-in CSV and JSON files are the numerical evidence used by the report and presentation. They are retained as report snapshots, not a claim that the project analysis ran through Python. The analytical workflow is CSV import followed by the PostgreSQL queries in ../sql/.

The paired-effect, forecast and scenario values are validated against those queries. Files such as dim_date, dim_market and original_* also support the separate Power BI report snapshot. Updating SQL data or changing a query does not automatically regenerate this directory or the dashboard.
