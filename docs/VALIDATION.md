# Validation

All results use synthetic data and illustrative accounting assumptions.

- Default-seed generation reproduces the four original processed CSVs byte-for-byte.
- Four standard-library test cases validate raw replay against every field of 2,688 market-day rows, assignment balance, financial bridge, holdout errors, future missing actuals, scenarios and the illustrative power calculation.
- The original data_import.sql table definitions and eight original PostgreSQL analysis files passed in a fresh isolated PostgreSQL 18.6 database, with CSVs imported in stages. Rebuilt daily finance differs from the original in zero rows. Forecast revenue and contribution MAEs reproduce $314.18 and $231.17.
- The publication presentation preserves all original visible slide XML, chart data and embedded workbook bytes. Speaker-note text and personal metadata are omitted from this copy.
- Native Power BI required version metadata is present and column/measure naming conflicts are resolved. Full Desktop refresh and rendering still require a Windows application check.
- Public text was checked for local personal paths, credential patterns and interview-coaching material. No such findings remain. No automated scan guarantees the absence of every possible sensitive item; review files before publishing.
- The HTML dashboard and presentation are fixed data snapshots, distinct from the executable generation and analysis pipeline.
