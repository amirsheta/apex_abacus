import sys, html, xml.etree.ElementTree as ET
NS='{http://xmlns.oracle.com/Forms}'
def load(p):
    fm=ET.parse(p).getroot().find(NS+'FormModule'); d={}
    U=lambda s: html.unescape(html.unescape(s or '')).replace('\r','')
    for t in fm.findall(NS+'Trigger'): d['FORM.'+t.get('Name')]=U(t.get('TriggerText'))
    for b in fm.findall(NS+'Block'):
        for t in b.findall(NS+'Trigger'): d[b.get('Name')+'.'+t.get('Name')]=U(t.get('TriggerText'))
        for i in b.findall(NS+'Item'):
            for t in i.findall(NS+'Trigger'): d[b.get('Name')+'.'+i.get('Name')+'.'+t.get('Name')]=U(t.get('TriggerText'))
    for p in fm.findall(NS+'ProgramUnit'): d['PU.'+p.get('Name')]=U(p.get('ProgramUnitText'))
    for p in fm.findall(NS+'ModuleParameter'): d['PARAM.'+p.get('Name')]=p.get('ParameterInitializeValue') or ''
    return d
a=load(sys.argv[1]); b=load(sys.argv[2])
for k in a:
    if not a[k].strip(): continue
    if k not in b: print('ONLY16', k, len(a[k].splitlines()))
    elif a[k].strip()!=b[k].strip(): print('DIFF', k, len(a[k].splitlines()))
