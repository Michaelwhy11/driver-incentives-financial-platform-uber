# Financial report

Five pages cover financial overview, experiment effects, data quality, forecasts and scenarios. All data are simulated.

The model contains 14 tables and 42 measures. DimMarket and DimDate filter Finance and Controls through four single-direction relationships. Pair-level effects, forecasts and alternative scenarios remain disconnected to preserve their respective grains. The fixed experiment summary is not intended to respond to daily descriptive slicers.

Open DriverIncentives.pbip in Power BI Desktop on Windows. Set the DataFolder parameter to this directory's data folder and refresh. Full numbers can be displayed by setting visual display units to None. No database credentials are included.

The project analysis uses the PostgreSQL queries in sql/ after CSV import. Export and map updated SQL results to the report CSVs explicitly; no automatic Python analysis-to-Power-BI synchronization is included. The HTML dashboard and presentation are separate fixed snapshots. CSV calculations and structural model checks do not establish native Desktop rendering compatibility. If Desktop reports a version/format error, check the application's supported PBIP/PBIR version before editing model files.
