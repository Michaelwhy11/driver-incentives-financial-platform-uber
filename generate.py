"""SIMULATED financial data platform. Python 3.10+; standard library only."""
import argparse, csv, hashlib, json, math, random, sqlite3, statistics
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def export(db, query, path):
    cur = db.execute(query)
    with path.open('w', newline='') as f:
        w = csv.writer(f); w.writerow([c[0] for c in cur.description]); w.writerows(cur)

def main():
    p = argparse.ArgumentParser(); p.add_argument('--seed', type=int, default=20261115)
    p.add_argument('--out', default='data'); args = p.parse_args()
    base = ROOT / args.out
    out = base / 'processed'; out.mkdir(parents=True, exist_ok=True)
    raw = base / 'raw'; raw.mkdir(parents=True, exist_ok=True)
    # In-memory rebuild; no existing database is deleted or partially mutated.
    db = sqlite3.connect(':memory:'); db.executescript((ROOT/'generation/sql/schema.sql').read_text())
    rng = random.Random(args.seed)
    db.execute('INSERT INTO run_config VALUES (?,?,?)',(args.seed,'2026-03-10T00:00:00','SIMULATED; not Uber data'))
    start = date(2026,1,5); ledger = {}; events = []; trip_no = 0
    for pair in range(24):
        treated = rng.randrange(2)
        pair_demand = rng.uniform(16,30)
        for side in range(2):
            cluster = pair*2+side; arm = 'treatment' if side==treated else 'control'
            db.execute('INSERT INTO cluster VALUES (?,?,?)',(cluster,pair,arm))
            base = pair_demand*rng.uniform(.94,1.06)
            for day in range(56):
                d = start+timedelta(days=day); ds = d.isoformat()
                post = day>=28; active = post and arm=='treatment'
                # Chosen, fictional effect: more completed trips under the policy.
                expectation = base*(1+.12*math.sin(2*math.pi*day/7))*(1+.0015*day)*(1.12 if active else 1)
                n = max(1,round(rng.gauss(expectation,math.sqrt(expectation))))
                totals = [0,0,0]
                for _ in range(n):
                    trip_no += 1; tid = f'T{trip_no:07}'
                    fare = rng.randint(1800,3500); driver = fare*3//4
                    refund = rng.randint(50,250) if rng.random()<.025 else 0
                    incentive = 110 if active else 40; cost = 65+fare*2//100
                    totals[0] += fare-driver-refund; totals[1] += incentive; totals[2] += cost
                    common = (cluster,ds)
                    initial = (f'{tid}-v1',tid,1,*common,ds+'T18:00:00',fare,driver,0,incentive,cost)
                    events.append(initial)
                    if trip_no%101==0:
                        events.append((f'{tid}-retry',*initial[1:]))
                    if refund:
                        arrival = (d+timedelta(days=2)).isoformat()+'T12:00:00'
                        events.append((f'{tid}-v2',tid,2,*common,arrival,fare,driver,refund,incentive,cost))
                ledger[(ds,cluster)] = totals
    # A malformed source record must be quarantined, not silently coerced.
    events.append(('BAD-v1','BAD',1,0,'2026-01-05','2026-01-05T18:00:00',-100,0,0,0,0))
    rng.shuffle(events)
    db.executemany('INSERT INTO raw_trip_event VALUES (?,?,?,?,?,?,?,?,?,?,?)',events)
    db.executemany('INSERT INTO ledger_daily VALUES (?,?,?,?,?)',[(d,c,*v) for (d,c),v in sorted(ledger.items())])
    db.executescript((ROOT/'generation/sql/models.sql').read_text())
    assert db.execute('SELECT COUNT(*) FROM fact_trip').fetchone()[0]==trip_no
    assert db.execute('SELECT COUNT(*) FROM quarantine').fetchone()[0]==1
    assert db.execute('SELECT COUNT(*) FROM reconciliation WHERE revenue_delta_cents!=0 OR incentive_delta_cents!=0 OR cost_delta_cents!=0').fetchone()[0]==0
    assert db.execute('SELECT COUNT(*) FROM daily_finance WHERE revenue_cents-incentive_cents-variable_cost_cents!=contribution_cents').fetchone()[0]==0
    # Reconciliation fault injection proves a one-cent discrepancy is detected.
    db.execute("UPDATE ledger_daily SET revenue_cents=revenue_cents+1 WHERE cluster_id=0 AND service_date='2026-01-05'")
    assert db.execute('SELECT COUNT(*) FROM reconciliation WHERE revenue_delta_cents!=0').fetchone()[0]==1
    db.execute("UPDATE ledger_daily SET revenue_cents=revenue_cents-1 WHERE cluster_id=0 AND service_date='2026-01-05'")
    # Early as-of excludes late versions. Restore before publishing the final snapshot.
    db.execute("UPDATE run_config SET as_of='2026-01-06T00:00:00'")
    assert db.execute('SELECT COUNT(*) FROM reconciliation WHERE revenue_delta_cents!=0').fetchone()[0]>0
    db.execute("UPDATE run_config SET as_of='2026-03-10T00:00:00'")
    rows = db.execute('SELECT * FROM experiment_cluster ORDER BY pair_id,arm').fetchall()
    metrics = {}; inference_rng = random.Random(args.seed+1)
    for label,pre,post in [('revenue',3,4),('contribution',5,6)]:
        differences=[]
        for i in range(0,len(rows),2):
            c,t=rows[i:i+2]
            differences.append(((t[post]-t[pre])-(c[post]-c[pre]))/100)
        observed = statistics.mean(differences)
        boot = sorted(statistics.mean(inference_rng.choices(differences,k=24)) for _ in range(5000))
        extreme=sum(abs(statistics.mean(v*inference_rng.choice([-1,1]) for v in differences))>=abs(observed) for _ in range(5000))
        metrics[label]={'adjusted_28_day_usd_per_cluster':round(observed,2),
          'paired_bootstrap_95_interval_usd':[round(boot[124],2),round(boot[4874],2)],
          'paired_randomization_two_sided_p_mc':(extreme+1)/5001}
    daily = db.execute('SELECT service_date,SUM(revenue_cents)/100.0 FROM daily_finance GROUP BY service_date ORDER BY service_date').fetchall()
    y=[r[1] for r in daily]
    # Last seven days are held out; predictions only use t-7.
    errors=[abs(y[i]-y[i-7]) for i in range(49,56)]
    forecast={'label':'SIMULATED descriptive seasonal-naive; not an incentive causal forecast',
      'holdout_days':7,'holdout_mae_usd':round(statistics.mean(errors),2),
      'holdout_wape':sum(errors)/sum(y[49:]),
      'next_7_days':[{'date':(start+timedelta(days=56+i)).isoformat(),'revenue_usd':round(y[49+i],2)} for i in range(7)]}
    export(db,'SELECT * FROM daily_finance ORDER BY service_date,cluster_id',out/'daily_finance.csv')
    export(db,'SELECT * FROM reconciliation ORDER BY service_date,cluster_id',out/'reconciliation.csv')
    export(db,'SELECT * FROM experiment_cluster ORDER BY cluster_id',out/'experiment_cluster.csv')
    export(db,'SELECT * FROM quarantine',out/'quarantine.csv')
    export(db,'SELECT * FROM raw_trip_event ORDER BY service_date,cluster_id,trip_id,version,ingested_at,event_id',raw/'raw_trip_event.csv')
    export(db,'SELECT * FROM cluster ORDER BY cluster_id',raw/'market_assignment.csv')
    export(db,'SELECT * FROM ledger_daily ORDER BY service_date,cluster_id',raw/'synthetic_financial_reference.csv')
    db.commit()
    dest=sqlite3.connect(str(out/'simulation.sqlite'))
    if hasattr(db, 'backup'):
        db.backup(dest)
    else:
        # Compatibility with older system Python/SQLite wrappers.
        existing = dest.execute("SELECT name,type FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' AND type IN ('view','table')").fetchall()
        for name, kind in sorted(existing, key=lambda item: item[1] != 'view'):
            dest.execute('DROP '+kind+' IF EXISTS "'+name.replace('"','""')+'"')
        dest.executescript('\n'.join(db.iterdump()))
    dest.close()
    report={'label':'ALL DATA AND RESULTS SIMULATED; not Uber data or policy', 'seed':args.seed,
      'completed_trips':trip_no,'raw_events':len(events),'clusters':48,'randomized_pairs':24,
      'checks':'PASS: deduplication, quarantine, reconciled amounts, contribution identity, injected discrepancy, early snapshot',
      'experiment':metrics,'forecast':forecast}
    (out/'results.json').write_text(json.dumps(report,indent=2)+'\n')
    manifest={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(out.glob('*.csv'))}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__': main()
