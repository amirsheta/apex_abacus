import sys,xml.etree.ElementTree as E
ns='{http://xmlns.oracle.com/Forms}'
for n in sys.argv[1:]:
    r=E.parse(n+'_fmb.xml').getroot()
    m=r.find(ns+'FormModule')
    print('##',n,'module',m.get('Name'),'title',m.get('Title'))
    for b in m.iter(ns+'Block'):
        print(' block',b.get('Name'),'query_ds',b.get('QueryDataSourceName'),'items',len(list(b.iter(ns+'Item'))))
    for rg in m.iter(ns+'RecordGroup'):
        q=rg.find(ns+'RecordGroupQuery')
        print(' RG',rg.get('Name'),(rg.get('RecordGroupQuery') or (q.text if q is not None else ''))[:400])
    for p in m.iter(ns+'FormParameter'): print(' PARAM',p.get('Name'),p.get('DataType'),p.get('InitializeValue'))
    for t in m.iter(ns+'Trigger'): print(' TRG',t.get('Name'),len(t.get('TriggerText') or ''))
