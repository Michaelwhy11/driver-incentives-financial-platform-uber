"""Validate raw replay, financial identities, experiment and forecast references."""
from pathlib import Path
from collections import defaultdict
import csv
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
def read(path):
    with (ROOT/path).open(newline='', encoding='utf-8') as handle:
        return list(csv.DictReader(handle))

class PipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw=read('data/raw/raw_trip_event.csv')
        cls.result=json.loads((ROOT/'analysis/results.json').read_text())

    def test_raw_replay_matches_all_daily_fields(self):
        latest={}
        for e in self.raw:
            if e['ingested_at']>'2026-03-10T00:00:00': continue
            key=(int(e['version']),e['ingested_at'],e['event_id'])
            if e['trip_id'] not in latest or key>latest[e['trip_id']][0]:
                latest[e['trip_id']]=(key,e)
        totals=defaultdict(lambda:[0]*6)
        invalid=0
        for _,e in latest.values():
            f,d,r,i,v=[int(e[k]) for k in ['fare_cents','driver_base_cents','refund_cents','incentive_cents','variable_cost_cents']]
            if min(f,d,r,i,v)<0 or d>f or r>f:
                invalid+=1
                continue
            values=[1,f,f-d-r,i,v,f-d-r-i-v]
            target=totals[(e['service_date'],e['cluster_id'])]
            for n,value in enumerate(values): target[n]+=value
        self.assertEqual(len(self.raw),65839)
        self.assertEqual(len({e['event_id'] for e in self.raw}),65839)
        self.assertEqual(len(latest),63624)
        self.assertEqual(invalid,1)
        fields=['trips','gross_bookings_cents','revenue_cents','incentive_cents','variable_cost_cents','contribution_cents']
        expected={(e['service_date'],e['cluster_id']):[int(e[k]) for k in fields] for e in read('data/processed/daily_finance.csv')}
        self.assertEqual(len(totals),2688)
        self.assertEqual(dict(totals),expected)

    def test_assignment_and_paired_bridge(self):
        assignment=read('data/raw/market_assignment.csv')
        for pair in range(24):
            self.assertEqual(sorted(e['arm'] for e in assignment if int(e['pair_id'])==pair),['control','treatment'])
        bridge=self.result['bridge']
        self.assertAlmostEqual(sum(e['effect_usd'] for e in bridge[:3]),bridge[3]['effect_usd'])
        self.assertAlmostEqual(self.result['effect_summary'][0]['effect_usd'],536.0754166667)
        self.assertAlmostEqual(self.result['effect_summary'][1]['effect_usd'],-103.3704166667)

    def test_forecast_metrics_and_future_nulls(self):
        m=self.result['forecast_metrics']
        self.assertEqual(round(m['revenue']['mae_usd'],2),314.18)
        self.assertEqual(round(m['contribution']['mae_usd'],2),231.17)
        for e in read('analysis/forecast_future.csv'): self.assertEqual(e['actual_revenue_usd'],'')
        for e in read('analysis/forecast_backtest.csv'): self.assertLess(e['cutoff_date'],e['forecast_date'])

    def test_scenarios_and_planning(self):
        t=next(e for e in read('analysis/breakeven_thresholds.csv') if float(e['incentive_usd'])==.6)
        self.assertAlmostEqual(float(t['required_trip_lift']),.041528979105)
        s=next(e for e in read('analysis/scenarios.csv') if float(e['incentive_usd'])==.6 and float(e['assumed_trip_lift'])==.06)
        self.assertEqual(round(float(s['incremental_contribution_usd']),2),58.75)
        p=json.loads((ROOT/'analysis/power_planning.json').read_text())
        self.assertEqual(p['required_pairs_approximate'],44)
        self.assertIn('Illustrative',p['label'])

if __name__=='__main__': unittest.main()
