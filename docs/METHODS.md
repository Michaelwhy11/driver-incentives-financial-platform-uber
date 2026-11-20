# Methodology

## Accounting and raw processing

The model uses a fictional ride service and USD. Source amounts remain integer cents. Gross bookings are rider fare before refunds. Base driver payable is floor(75% of fare), an illustrative pass-through. Revenue equals fare minus base driver payable minus platform-funded refunds. Incentives are modeled supplier expense, and other variable cost equals $0.65 plus floor(2% of fare). Contribution deducts incentives and other variable costs and excludes fixed overhead.

The pipeline filters deliveries to an as-of cutoff before selecting the highest version, latest ingestion timestamp and greatest event_id per trip. Full replacement refund snapshots restate the original service date. They are not additive events. The latest snapshot is validated, with no fallback if it is invalid. Negative amounts, driver payable above fare and refund above fare fail validation. The negative-fare fixture triggers three rules but remains one quarantined record.

A fully refunded completed trip would remain a trip and could generate negative modeled revenue, but the generator creates only partial refunds. Cancellations, unsuccessful payments, taxes, tolls, FX, subscriptions and settlement are not modeled. Accounting classification requires contract review. A pure reclassification of incentives to contra-revenue changes revenue presentation but leaves contribution unchanged if costs are deducted once.

The synthetic financial reference uses a separate generation path but shares underlying simulated truth. Checks cover unique keys, counts, contribution identities, reconciliation, a one-cent injected discrepancy and a deliberately early cutoff. Agreement demonstrates consistency, not independent ledger certification.

## SQL analytical workflow

CSV fixtures are imported through pgAdmin using the table definitions in sql/data_import.sql. The raw-to-daily query uses CTEs and persists daily_finance. The remaining PostgreSQL files perform period summaries, paired inference, bridge checks, inspection of imported reconciliation/quarantine reports, forecasts and scenarios. Generator SQL stays under generation/sql and is not this analytical path.

## Geographic experiment

Each synthetic demand pair contains two markets, with one randomly selected to treatment using seed 20261115. They share a pair-level demand draw and have individual variation. This is not a fitted real-data matching algorithm.

The experiment uses equal 28-day baseline and treatment windows. Baseline assignment labels identify future exposure. The estimator subtracts control change from treatment change within each pair and averages over 24 independent pairs with equal weights. Trips are not independent randomized observations.

The approximate t interval equals mean effect plus or minus 2.068657610 times sample SD divided by square root of 24. It assumes independent pairs and an adequate distributional approximation, without multiplicity adjustment. The generator also produces a separately labeled percentile bootstrap and Monte Carlo sign-flip test. These interval methods must not be mixed.

The simulator imposes an expected 12% trip multiplier for treated markets. Spillovers, noncompliance, endogenous pricing and long-term equilibrium are absent. The outputs do not establish a real policy effect or launch decision.

## Forecast evaluation

The driver model trains on the 14 days ending at the cutoff. It averages two same-weekday trip counts within each arm and multiplies volume by ratios of training financial totals to trips. The holdout is February 23–March 1, with cutoff February 22. No holdout actual enters training.

Errors aggregate both groups to platform-day totals before taking absolute differences. MAE is average absolute daily error; WAPE is total absolute error divided by total absolute actual outcome. Signed error uses actual minus predicted. The seven-calendar-day seasonal naive benchmark has lower error on this holdout. The separate March 2–8 outlook has no actuals. Neither forecast provides calibrated prediction intervals or identifies response to a new incentive.

## Scenarios and power

Reference inputs are experiment-period control markets: 660.4167 trips and $3,312.59 contribution per market over 28 days, revenue/trip $6.5907533, other cost/trip $1.1748391 and incentive $0.40. Each alternative incentive applies to all scenario trips.

Contribution-preserving growth equals (new incentive − old incentive) / (revenue/trip − other cost/trip − new incentive), provided the denominator is positive. Unit rates are fixed assumptions. For $0.60 the exact threshold is 4.1528979105%; rounded 4.15% is slightly below it.

The original 24-pair design was not prospectively powered. With $100 contribution MDE over 28 days, two-sided alpha 0.05, power 0.80 and simulated paired SD about $236.03, the normal approximation gives 43.73 pairs, rounded up to 44. Real planning needs representative historical variance, finite-sample calculations or simulation, and predefined guardrails. This estimate is an illustrative extension.

## References

- [Marketplace cluster randomization](https://business.columbia.edu/faculty/research/reducing-interference-bias-online-marketplace-experiments-using-cluster)
- [Paired-test power](https://www.statsmodels.org/stable/generated/statsmodels.stats.power.TTestPower.solve_power.html)
- [PostgreSQL window functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- [Power BI projects](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview)
