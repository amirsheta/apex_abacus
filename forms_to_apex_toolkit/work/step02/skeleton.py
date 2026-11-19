import json, re, sys
units = json.load(open('work/step02/units.json', encoding='utf-8'))
want = [('IMPORTERS', 'POST-QUERY'), ('IMPORTERS.IMPR_TYPE_CD', 'WHEN-VALIDATE-ITEM'), ('IMPORTERS.BUS_ID', 'WHEN-VALIDATE-ITEM'),
        ('IMPORTERS.BUS_ID_BRNCH', 'WHEN-VALIDATE-ITEM'), ('IMPORTERS', 'PRE-INSERT'), ('IMPORTERS', 'POST-INSERT'),
        ('IMPORTERS', 'POST-UPDATE'), ('IMPORTERS', 'PRE-UPDATE'), ('IMPORTERS', 'WHEN-CREATE-RECORD'),
        ('IMPORTERS.COMM_RGSTRTN_TYPE', 'WHEN-LIST-CHANGED'), ('FORM', 'WHEN-NEW-FORM-INSTANCE'),
        ('IMPORTERS.IMPR_TYPE_CD', 'KEY-LISTVAL'), ('IMPORTERS.IMPR_TYPE_CD', 'POST-CHANGE'),
        ('IMPORTERS.IMPR_TYPE_CD', 'WHEN-NEW-ITEM-INSTANCE'), ('IMPORTERS.BUS_ID_TYPE_CD', 'POST-CHANGE'),
        ('IMPORTERS.CITY_CODE_OF_ID', 'WHEN-NEW-ITEM-INSTANCE'), ('IMPORTERS.BUS_ID', 'WHEN-NEW-ITEM-INSTANCE'),
        ('IMPORTERS.BRNH_CITY_CD', 'WHEN-NEW-ITEM-INSTANCE'), ('IMPORTERS.BUS_ID_BRNCH', 'WHEN-NEW-ITEM-INSTANCE'),
        ('PROGRAM UNITS', 'BROKER_INT')]
KEEP = re.compile(r"(?i)^\s*(IF\b|ELSIF\b|ELSE\b|END\s+IF|.*make_field_entrable|.*set_item_property|RAISE\b|.*DispAlert|.*DispArbMsg|EXCEPTION\b|WHEN\s+\w+\s+THEN|.*:=\s*\d+\s*;\s*$)")
for o, n in want:
    u = [x for x in units if x['owner'] == o and x['name'] == n]
    if not u:
        print('### MISSING', o, n)
        continue
    c = re.sub(r'/\*.*?\*/', '', u[0]['code'], flags=re.S)
    out = []
    for l in c.split('\n'):
        s = l.split('--')[0].rstrip()
        if s.strip() and KEEP.match(s):
            out.append(s.replace('\t', '  ')[:150])
    print('### %s %s (%d active lines, %d skeleton lines)' % (o, n, u[0]['active'], len(out)))
    print('\n'.join(out))
