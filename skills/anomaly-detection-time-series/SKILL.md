---
name: anomaly-detection-time-series
description: Formal time-series methods that augment the hand-coded fingerprint library in traffic-change-diagnosis. Use this skill when traffic-change-diagnosis fingerprints overlap, when the user asks "is this real?", or when the change date is contested. Applies STL decomposition, Bayesian online changepoint detection, Prophet, quantile regression, sequential probability ratio test, and Granger causality. Use whenever interpreting a series where day-of-week confounds an eyeballed drop, where two candidate causes share a week, or where an alert needs to fire before an analyst sees the chart. Pairs with analytics-diagnostic-method for the surrounding investigation and with sequential-monitoring for the SPRT details. Triggers when Clamp MCP traffic_timeseries returns a series spanning more than 14 days, or when via Clamp the user shares a daily/hourly metric history that needs a non-eyeball verdict.
when_to_use: When two traffic-change-diagnosis fingerprints fit the same drop with similar confidence and one needs to be picked. When the user asks "is this drop real?" or "did this actually start Tuesday?". When the change date itself is being argued about. When the question is a counterfactual ("where would we be without the drop?"). When two events (deploy + algorithm update + holiday) collided in the same week and only one is the real cause.
---

# Anomaly detection for time series

The fingerprint library in `traffic-change-diagnosis` is a fast first pass: it pattern-matches the *shape* of a drop against twelve common causes. It is right most of the time and wrong when it matters most — when two fingerprints fit the same shape, when the user's eyeballed change date is off by a day, or when a counterfactual baseline is needed instead of a slope match. This skill adds six formal methods that resolve those cases. None of them replace the fingerprints; they adjudicate when fingerprints conflict.

## When NOT to use this

- The fingerprint match is unambiguous (single hypothesis, >0.7 confidence in the diagnosis worksheet). Running STL or BOCD on a clean tracking-regression drop is ceremony.
- The series is shorter than 14 days. STL needs at least two full seasonal cycles; BOCD's posterior is noisy with less than ~30 observations; Prophet needs more history than that to fit changepoints. For short series, stick to `analytics-diagnostic-method`'s denominator + sample-size discipline.
- The user wants a real-time alert on a single metric and hasn't already decided what "anomalous" means. That's a monitoring-design conversation, not a detection method; load `sequential-monitoring` instead.
- The metric is count-based with most days at zero (e.g. a niche conversion event). STL and Prophet assume continuous-ish residuals; you'll get nonsense decompositions. Use Poisson-tail tests instead.

## Pick one method per question

Do not run all six on every series. Each method answers a different question. Pick by question shape:

| Question | Method | Output |
|---|---|---|
| Is the change date the user gave actually the change date? | BOCD | Posterior P(changepoint = day t) for every t |
| Is today's number real, or is Tuesday always like this? | STL decomposition | Residual z-score against seasonal baseline |
| Where would the series be without the drop? | Prophet | Forecast interval treating pre-drop as baseline |
| Is *this hour* anomalous, given the usual hour-of-day spread? | Quantile regression | P10/P50/P90 bands per hour |
| Should the alert fire now or wait for more data? | SPRT | Log-likelihood ratio crossing a Wald boundary |
| X and Y both happened this week — did X precede Y predictively? | Granger causality | F-test on lagged regressors |

If the question doesn't appear in this table, you're probably back in fingerprint territory. Don't reach for these.

## The six methods

### Method 1. STL decomposition (Cleveland 1990)

STL — Seasonal-Trend decomposition using LOESS — splits the series into three additive components: a smooth trend, a periodic seasonal, and a residual. Each is fit by iterated LOESS smoothing, alternating between trend-pass and seasonal-pass until they converge.

The trend captures slow drift. The seasonal captures day-of-week (period=7) or hour-of-day (period=24) cycles. The residual is what's left — and that's where anomalies show up.

**Use it when:** the drop falls on a structurally low day. A Tuesday tracking regression looks identical to "Tuesdays are slow." STL's residual z-scores the day against its own seasonal baseline, so a -30% drop on a normally -25% Tuesday flags as +0.5σ residual (nothing), while a -30% drop on a normally +10% Tuesday flags as -3σ (real).

**How to read it:** compute residual / stdev(residual) over a clean window. |z| > 2.5 is a flag, |z| > 3.0 is a real anomaly. Robust STL (the default in `statsmodels.tsa.seasonal.STL`) handles outliers in the fit itself by downweighting them in the LOESS pass, so a single bad day doesn't poison the seasonal estimate.

**Knobs that matter:**

| Parameter | Default | When to change |
|---|---|---|
| `period` | required | 7 for daily web traffic, 24 for hourly, 168 for hourly with weekly cycle |
| `seasonal` | 7 | Larger window = smoother seasonal; raise if seasonal is bouncing |
| `trend` | auto | Lower if trend over-smooths real shifts; raise if it tracks noise |
| `robust` | False | Set True if you have known outliers (deploys, holidays) in the window |

**Limit:** STL assumes additive structure. Multiplicative seasonality (traffic that scales proportionally with the trend) needs a log transform first — fit STL on log(y) and exponentiate the components.

### Method 2. Bayesian online changepoint detection (Adams & MacKay 2007)

BOCD maintains a posterior distribution over the *run length* — how many days have passed since the last changepoint. At each new observation it updates the posterior by message-passing: P(run_length = r | data) is computed by combining the prior hazard rate with the predictive likelihood under the current run.

The output is P(changepoint at day t) for every t in the series. Peaks in this posterior are the algorithm's best guesses for when the regime actually shifted.

**Use it when:** the user says "the drop started Tuesday" but the deploy was Friday — or vice versa. BOCD pins the date probabilistically instead of relying on whoever happened to be watching the chart that morning.

**How to read it:** plot the posterior. A sharp peak at one date is a confident changepoint. A broad hump over three days means the algorithm can't resolve it finer than that — usually because the signal-to-noise at that scale doesn't support it. Multiple peaks mean multiple regime shifts; report each separately with its posterior mass.

**Sanity check:** the posterior should integrate to ~1 over the observed range. If most of the mass is at "no changepoint detected," BOCD is telling you the series is consistent with a single regime — believe it, and stop looking for a changepoint that isn't there.

**Limit:** the hazard prior (1/expected_run_length) is a knob. Set it too tight and every weekend looks like a changepoint; too loose and slow drifts go undetected. A hazard of 1/100 is a reasonable default for daily web traffic; 1/30 if you expect more frequent regime shifts (e.g. an actively iterating product); 1/365 for annual-level shifts.

### Method 3. Prophet (Meta)

Prophet is a decomposable additive model: y(t) = trend(t) + seasonality(t) + holidays(t) + error. Trend is piecewise-linear with automatic changepoint detection. Seasonality is Fourier-series. Holidays are user-supplied dummies. The whole thing fits in Stan and exposes uncertainty intervals.

**Use it when:** the question is counterfactual. "Where would traffic be if the drop hadn't happened?" Fit Prophet on the pre-drop window, forecast forward, and the 80% interval is your baseline. Actuals outside the interval = anomaly; the gap between actual and forecast median = the size of the drop.

**How to read it:** the forecast interval is the no-drop counterfactual. If the actual sits 30% below the median and outside the 80% band for five consecutive days, that's the drop magnitude with calibrated uncertainty. Prophet's `changepoint_prior_scale` (default 0.05) controls how reactive trend changes are; bump it to 0.5 if real regime shifts are getting smoothed away.

**Strength:** business-friendly output, handles holidays cleanly, the forecast interval reads as a baseline without explanation.

**Limit:** Prophet is bad at abrupt regime shifts. The piecewise-linear trend wants to bend, not break. For a true step-function drop, BOCD will pin the date better and STL will quantify the residual better; Prophet's role is the *baseline*, not the *detection*.

### Method 4. Quantile regression for anomaly scoring

Web traffic is log-normal-ish and heteroscedastic — variance is not constant across hours of the day or across weeks of the year. A mean ± stdev envelope flags every Friday evening as anomalous and misses real weekend spikes because the weekend variance is wider.

Quantile regression fits the conditional quantiles directly. Instead of modeling E[Y | hour_of_day] with a constant residual, fit Q_p(Y | hour_of_day) for p ∈ {0.1, 0.5, 0.9} — three separate regressions, each minimizing the pinball loss for that quantile.

**Use it when:** anomaly bands need to be per-context (per hour of day, per day of week, per channel). The P5/P95 envelope is a real anomaly threshold; the 2-sigma envelope is a Gaussian fantasy applied to a non-Gaussian process.

**How to read it:** points outside the P5/P95 band are tail events. The bands' *width* itself is informative — a wide band at 3am means that hour is naturally unpredictable; a sudden spike in band width signals regime change in the variance, not just the mean.

**Limit:** quantile regression needs enough samples per context. With hourly data and per-hour-of-day quantiles, you need at least ~30 days for stable bands.

### Method 5. Sequential probability ratio test (Wald 1945)

Same SPRT machinery as in the `sequential-monitoring` skill, applied to anomaly streams instead of A/B test conversions. At each new observation, compute the log-likelihood ratio of "H1: regime has shifted" vs "H0: same regime." Fire the alert when the cumulative log-LR crosses an upper boundary log(β/(1-α)); accept null when it crosses lower boundary log((1-β)/α).

**Use it when:** the question is "should the alert fire *now* or wait for more data?" SPRT gives a principled stopping rule. Without it, an engineer eyeballs a sparkline and either calls it too early (false positive) or sits on it too long (false negative).

**How to read it:** the boundaries are set by α (false-positive rate) and β (false-negative rate) and the effect size you care about. For α=β=0.05 and a 20% drop hypothesis, the upper boundary is log(0.05/0.95) ≈ -2.94 and lower is log(0.95/0.05) ≈ 2.94. Sum the per-observation log-LRs; cross either boundary, stop and report.

**Cross-link:** the SPRT math, including the mSPRT extension for sequential A/B tests, lives in `sequential-monitoring`. Load that skill if the application is conversion-rate monitoring rather than pure anomaly streams.

**Limit:** SPRT requires a parametric likelihood. For non-Gaussian or unknown-distribution streams, the non-parametric variant (CUSUM) is the working substitute.

### Method 6. Granger causality

Granger causality tests whether the past of series X improves the forecast of series Y beyond what Y's own past predicts. It's an F-test comparing two regressions: Y_t ~ Y_{t-1..k} vs Y_t ~ Y_{t-1..k} + X_{t-1..k}. If the second model fits significantly better, X "Granger-causes" Y.

**Use it when:** two candidate causes share a week. Deploy on Monday, algorithm update on Tuesday, traffic drops on Wednesday — which one is it? Granger-test deploy_indicator → traffic and algo_update_indicator → traffic separately. The one with significant predictive content at the right lag is your suspect.

**How to read it:** a low p-value on the F-test means lagged X improves the forecast — temporal precedence with predictive content. It does *not* prove causation in the philosophical sense; confounders can produce Granger-causality. But it rules out the reverse direction and rules out coincidence.

**Limit:** requires stationarity. Difference the series first (or use a VAR with cointegration testing) if either has a trend. And Granger fails completely when the true cause is contemporaneous or instantaneous — by construction it only sees lagged effects.

## Traps to avoid

- **Running all six methods because they're available.** Each method answers a specific question; picking from the table above is the discipline. Stacking them on the same series produces six confidence numbers, multiplies your false-positive rate, and obscures which method actually answered the user's question.
- **Trusting STL residuals on a non-stationary series.** If the trend is moving fast, the LOESS trend-pass eats some of the anomaly and the residual under-reports it. Detrend first (first-difference, or fit on a window short enough that the trend is locally flat) before z-scoring.
- **Reading a BOCD posterior peak as causation.** The peak says "the regime shifted around this date." It does not say what caused the shift. Cross-reference the peak against deploy logs, marketing campaigns, and external events before naming a cause.
- **Confusing Prophet's forecast interval with statistical significance.** Prophet's 80% interval is a *predictive* interval, not a confidence interval on a parameter. Five actuals outside the band don't mean p < 0.05; they mean the model's prior on volatility was wrong, the regime shifted, or both.
- **Per-hour quantile bands on a weekly-seasonal series.** If the series has both intra-day and intra-week structure, hour-of-day quantiles will be wide on weekend hours and tight on weekday hours unless you condition on both. Fit Q_p(Y | hour_of_day, day_of_week) jointly, not marginally.
- **Granger causality on a known confounder.** If a marketing push (X) and traffic (Y) are both responses to a holiday, Granger will happily report X → Y because the holiday's effect on X happens earlier in the day than its effect on Y. Control for known confounders by including them as additional regressors, or by running the test on residuals after partialling them out.
- **SPRT without a pre-committed effect size.** The alpha and beta boundaries depend on the effect size you're testing for. Engineers tuning the boundary post-hoc until "the alert fires when it should" reinvent p-hacking. Pick the effect size before the data arrives.

## Worked example: 30-day traffic series, eyeballed drop on day 14

```
User: traffic dropped around day 14, can you confirm and find the cause?

Agent: Series is 30 days, daily granularity. Two questions:
  (1) is the day-14 drop real and on day 14, or did the user eyeball?
  (2) what shifted around that date?

Pick: STL for the residual, BOCD for the date, Prophet for the baseline.

[STL]
  Period = 7 (weekly seasonal). Robust LOESS fit.
  Day 14 residual: -2.8σ. Day 15: -2.4σ. Day 16: -2.1σ.
  -> Real anomaly, not seasonality. The drop is structural.

[BOCD]
  Hazard = 1/30. Posterior over changepoints:
    day 11: P=0.06
    day 12: P=0.41  <- peak
    day 13: P=0.18
    day 14: P=0.09
  -> Changepoint is day 12, not day 14. The user eyeballed it two
  days late because day 12-13 were already low and day 14 was the
  first weekday after that the chart looked obviously broken.

[Prophet]
  Fit on days 1-11, forecast days 12-30.
  Day 14 forecast median: 1,200 (80% interval: 1,050-1,360).
  Day 14 actual: 800.
  -> Actual is 400 below median, well outside the 80% band. The
  counterfactual baseline confirms the gap is ~33%.

[Cross-check against deploys]
  Deploy log shows a release on day 12 at 14:00.
  -> BOCD posterior peak aligns with the deploy timestamp, not the
  user's eyeballed date. Tracking regression is the leading
  hypothesis. Hand back to traffic-change-diagnosis with the
  refined date and the three confirming signals.

VERDICT: Drop is real (STL z = -2.8σ), started day 12 not day 14
  (BOCD posterior peak), magnitude ~33% vs baseline (Prophet
  counterfactual). Day-12 deploy is the prime suspect.
```

## Worked example: two fingerprints fit, BOCD breaks the tie

```
User: Organic traffic dropped 40% over a week. Could be algo update or
  could be the tracking regression you flagged last month — both fit
  the slope.

Agent: traffic-change-diagnosis returned two candidates with similar
  confidence (algo-update 0.55, tracking-regression 0.50). Pick BOCD.

[BOCD]
  Hazard = 1/60 (organic algo updates rare). Posterior:
    day 41: P=0.08
    day 42: P=0.11
    day 43: P=0.62  <- peak, this is a Friday
    day 44: P=0.14
  -> Sharp single-day changepoint on a Friday.

[Cross-reference]
  Tracking regression hypothesis predicts gradual, build-driven decay
  (changepoint should align with a deploy). Last deploy was day 38;
  no deploy day 41-44.
  Algo update hypothesis predicts an abrupt single-day step on
  Google's release schedule. Google announced a core update rolling
  out day 43.
  -> BOCD peak aligns with algo-update date, not deploy date.
  Tie broken: algo update wins.

VERDICT: Core algorithm update on day 43. Tracking regression
  hypothesis ruled out by changepoint timing — a tracking bug would
  have shown a gradual posterior, not a sharp single-day peak two
  days after the most recent deploy.
```

## What to ask the user before running anything

The methods are sharp but the questions are blunt. Before reaching for STL or Prophet, pin down three things:

1. **What is the unit and granularity of the series?** Daily sessions, hourly pageviews, weekly conversions. STL's `period` parameter, BOCD's hazard rate, and quantile regression's conditioning variables all depend on this. A 30-day daily series has 30 points; a 30-day hourly series has 720. They are not interchangeable.
2. **What does the user think happened, and when?** "Drop around Tuesday" is enough. The user's hypothesis is the H1 you're testing against the null of "no regime shift." If they don't have one, BOCD is the right starting method because it doesn't require one.
3. **What's the cost of a wrong answer?** A false-positive anomaly alert wastes engineer time. A false-negative misses a real revenue regression. Different cost ratios call for different α and β when SPRT or quantile thresholds are involved. Default to α = β = 0.05 if no preference; lower α (e.g. 0.01) when alerts are expensive to investigate.

If the user can't answer (1), the series is too underspecified to model. If they can't answer (2), start with BOCD. If they can't answer (3), default to α = β = 0.05 and flag the assumption in the verdict.

## Workflow: from fingerprint conflict to formal verdict

1. **Start in `traffic-change-diagnosis`.** Run the fingerprint pass. If a single fingerprint wins by more than 0.2 confidence over the runner-up, ship that answer.
2. **If two fingerprints tie within 0.2,** identify the discriminating question. Which fingerprint predicts which date? Which one predicts a sharp step vs a gradual decline? Which one predicts seasonality vs structural?
3. **Map the discriminating question to a method** using the table at the top of this skill. Date contested → BOCD. Sharp vs gradual → Prophet (gradual fits its piecewise-linear trend; sharp doesn't). Real vs seasonal → STL residual.
4. **Run exactly that method.** Report its output as the tiebreaker. Hand the refined hypothesis back to `traffic-change-diagnosis` for the final narrative.
5. **If no method discriminates,** the honest answer is "both fingerprints remain plausible, here's what would discriminate them with more data." That's a real answer, not a failure.

## Cross-references

- **`traffic-change-diagnosis`**: the upstream skill this one augments. Fingerprints first, formal methods only when fingerprints conflict.
- **`analytics-diagnostic-method`**: the surrounding investigation framework. STL residuals and BOCD posteriors feed the diagnostic worksheet; they don't replace it.
- **`sequential-monitoring`**: full SPRT and mSPRT math for A/B tests and live alerting. Method 5 above is the short version; load this skill for the boundary derivations.
- **`channel-and-funnel-quality`**: when STL or quantile regression is being applied per-channel, that skill's expected-quality ranges calibrate "is this channel's variance normally wide."

## Tool invocations

The methods are platform-neutral but assume a daily or hourly series. With Clamp MCP, pull the series via `traffic_timeseries` at the right grain (daily for STL/BOCD/Prophet, hourly for quantile bands, sub-hourly for SPRT alerting). For other platforms, see [`tool-maps/`](../../tool-maps/) and the `tool_map:` field in `analytics-profile.md`.

The Python implementations are standard:

- STL: `from statsmodels.tsa.seasonal import STL; STL(y, period=7, robust=True).fit()`
- BOCD: `bayesian_changepoint_detection` package on PyPI, or the reference implementation linked in Sources
- Prophet: `from prophet import Prophet; m = Prophet(); m.fit(df); m.predict(future)`
- Quantile regression: `statsmodels.regression.quantile_regression.QuantReg`, or `sklearn.linear_model.QuantileRegressor`
- SPRT: hand-rolled in a dozen lines; see the `sequential-monitoring` skill for the reference snippet
- Granger: `statsmodels.tsa.stattools.grangercausalitytests`

None of these require GPU or paid services. A laptop fits the whole pipeline on a year of daily traffic in seconds.

## Sources

- Cleveland, Cleveland, McRae, Terpenning (1990). *STL: A Seasonal-Trend Decomposition Procedure Based on Loess.* Journal of Official Statistics 6(1): 3-73.
- Adams & MacKay (2007). [*Bayesian Online Changepoint Detection*](https://arxiv.org/abs/0710.3742). arXiv:0710.3742.
- Hyndman & Athanasopoulos, [FPP3 §3.6 STL decomposition](https://otexts.com/fpp3/stl.html).
- [Prophet documentation](https://facebook.github.io/prophet/) (Meta).
- [statsmodels STL decomposition notebook](https://www.statsmodels.org/dev/examples/notebooks/generated/stl_decomposition.html).
- [Python BOCD implementation (hildensia/bayesian_changepoint_detection)](https://github.com/hildensia/bayesian_changepoint_detection).
- [Granger causality (Wikipedia)](https://en.wikipedia.org/wiki/Granger_causality).
- Gundersen, [*Bayesian Online Changepoint Detection* walkthrough](https://gregorygundersen.com/blog/2019/08/13/bocd/).
- Wald (1945). *Sequential Tests of Statistical Hypotheses.* Annals of Mathematical Statistics 16(2): 117-186. (SPRT origin.)
