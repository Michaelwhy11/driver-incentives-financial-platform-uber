// Each section below is a separate Power Query query.
// All data are simulated.

// Parameter: DataFolder
"C:\UberProject1\data" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// Query: DimMarket
let
    Source = Csv.Document(File.Contents(DataFolder & "\dim_market.csv"), [Delimiter=",", Columns=3, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"cluster_id", Int64.Type}, {"pair_id", Int64.Type}, {"assigned_group", type text}}, "en-US")
in
    Typed

// Query: DimDate
let
    Source = Csv.Document(File.Contents(DataFolder & "\dim_date.csv"), [Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"date", type date}, {"weekday", type text}, {"weekday_number", Int64.Type}, {"period", type text}}, "en-US")
in
    Typed

// Query: Finance
let
    Source = Csv.Document(File.Contents(DataFolder & "\finance.csv"), [Delimiter=",", Columns=11, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"service_date", type date}, {"cluster_id", Int64.Type}, {"trips", Int64.Type}, {"gross_bookings_cents", Int64.Type}, {"revenue_cents", Int64.Type}, {"incentive_cents", Int64.Type}, {"variable_cost_cents", Int64.Type}, {"contribution_cents", Int64.Type}, {"pair_id", Int64.Type}, {"assigned_group", type text}, {"period", type text}}, "en-US")
in
    Typed

// Query: PairEffects
let
    Source = Csv.Document(File.Contents(DataFolder & "\pair_effects.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"pair_id", Int64.Type}, {"treatment_market", Int64.Type}, {"control_market", Int64.Type}, {"trips_effect", type number}, {"gross_bookings_effect_usd", type number}, {"revenue_effect_usd", type number}, {"incentive_effect_usd", type number}, {"variable_cost_effect_usd", type number}, {"contribution_effect_usd", type number}}, "en-US")
in
    Typed

// Query: EffectSummary
let
    Source = Csv.Document(File.Contents(DataFolder & "\effect_summary.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"metric", type text}, {"pairs", Int64.Type}, {"effect_usd", type number}, {"standard_deviation_usd", type number}, {"standard_error_usd", type number}, {"ci_lower_usd", type number}, {"ci_upper_usd", type number}, {"interval_method", type text}, {"unit", type text}}, "en-US")
in
    Typed

// Query: Bridge
let
    Source = Csv.Document(File.Contents(DataFolder & "\financial_bridge.csv"), [Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"sort_order", Int64.Type}, {"component", type text}, {"effect_usd", type number}, {"is_total", Int64.Type}}, "en-US")
in
    Typed

// Query: PeriodSummary
let
    Source = Csv.Document(File.Contents(DataFolder & "\period_summary.csv"), [Delimiter=",", Columns=10, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"period", type text}, {"assigned_group", type text}, {"markets", Int64.Type}, {"market_days", Int64.Type}, {"trips", Int64.Type}, {"gross_bookings_usd", type number}, {"revenue_usd", type number}, {"incentive_usd", type number}, {"variable_cost_usd", type number}, {"contribution_usd", type number}}, "en-US")
in
    Typed

// Query: Controls
let
    Source = Csv.Document(File.Contents(DataFolder & "\controls.csv"), [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"service_date", type date}, {"cluster_id", Int64.Type}, {"revenue_delta_cents", Int64.Type}, {"incentive_delta_cents", Int64.Type}, {"cost_delta_cents", Int64.Type}}, "en-US")
in
    Typed

// Query: Quarantine
let
    Source = Csv.Document(File.Contents(DataFolder & "\quarantine.csv"), [Delimiter=",", Columns=8, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"event_id", type text}, {"trip_id", type text}, {"cluster_id", Int64.Type}, {"service_date", type date}, {"fare_cents", Int64.Type}, {"primary_reason", type text}, {"rule_violations", Int64.Type}, {"resolution", type text}}, "en-US")
in
    Typed

// Query: QualityChecks
let
    Source = Csv.Document(File.Contents(DataFolder & "\quality_checks.csv"), [Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"check", type text}, {"observed", Int64.Type}, {"expected", Int64.Type}, {"status", type text}}, "en-US")
in
    Typed

// Query: Backtest
let
    Source = Csv.Document(File.Contents(DataFolder & "\forecast_backtest.csv"), [Delimiter=",", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"forecast_date", type date}, {"assigned_group", type text}, {"cutoff_date", type date}, {"estimated_trips", type number}, {"estimated_revenue_per_trip_usd", type number}, {"estimated_incentive_per_trip_usd", type number}, {"estimated_variable_cost_per_trip_usd", type number}, {"predicted_revenue_usd", type number}, {"predicted_incentive_usd", type number}, {"predicted_variable_cost_usd", type number}, {"predicted_contribution_usd", type number}, {"actual_trips", Int64.Type}, {"actual_revenue_usd", type number}, {"actual_contribution_usd", type number}}, "en-US")
in
    Typed

// Query: Future
let
    Source = Csv.Document(File.Contents(DataFolder & "\forecast_future.csv"), [Delimiter=",", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    BlanksToNull = Table.ReplaceValue(Headers, "", null, Replacer.ReplaceValue, Table.ColumnNames(Headers)),
    Typed = Table.TransformColumnTypes(BlanksToNull, {{"forecast_date", type date}, {"assigned_group", type text}, {"cutoff_date", type date}, {"estimated_trips", type number}, {"estimated_revenue_per_trip_usd", type number}, {"estimated_incentive_per_trip_usd", type number}, {"estimated_variable_cost_per_trip_usd", type number}, {"predicted_revenue_usd", type number}, {"predicted_incentive_usd", type number}, {"predicted_variable_cost_usd", type number}, {"predicted_contribution_usd", type number}, {"actual_trips", Int64.Type}, {"actual_revenue_usd", type number}, {"actual_contribution_usd", type number}}, "en-US")
in
    Typed

// Query: Scenarios
let
    Source = Csv.Document(File.Contents(DataFolder & "\scenarios.csv"), [Delimiter=",", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Headers, {{"scenario_id", type text}, {"incentive_usd", type number}, {"assumed_trip_lift", type number}, {"required_trip_lift", type number}, {"trip_lift_cushion_pp", type number}, {"baseline_trips", type number}, {"estimated_trips", type number}, {"predicted_revenue_usd", type number}, {"predicted_incentive_usd", type number}, {"predicted_variable_cost_usd", type number}, {"predicted_contribution_usd", type number}, {"baseline_contribution_usd", type number}, {"incremental_contribution_usd", type number}, {"scenario_result", type text}}, "en-US")
in
    Typed

// Query: Thresholds
let
    Source = Csv.Document(File.Contents(DataFolder & "\breakeven_thresholds.csv"), [Delimiter=",", Columns=8, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Headers, {{"incentive_usd", type number}, {"required_trip_lift", type number}, {"baseline_incentive_usd", type number}, {"revenue_per_trip_usd", type number}, {"variable_cost_per_trip_usd", type number}, {"new_contribution_per_trip_usd", type number}, {"baseline_contribution_usd", type number}, {"unit", type text}}, "en-US")
in
    Typed
