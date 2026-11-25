import sys, html, xml.etree.ElementTree as ET
NS='{http://xmlns.oracle.com/Forms}'
def load(p):
    fm=ET.parse(p).getroot().find(NS+'FormModule'); d={}
    def U(s): return html.unescape(html.unescape(s or '')).replace('\r','')
    for t in fm.findall(NS+'Trigger'): d['FORM.'+t.get('Name')]=U(t.get('TriggerText'))
    for b in fm.findall(NS+'Block'):
        for t in b.findall(NS+'Trigger'): d[b.get('Name')+'.'+t.get('Name')]=U(t.get('TriggerText'))
        for i in b.findall(NS+'Item'):
            for t in i.findall(NS+'Trigger'): d[b.get('Name')+'.'+i.get('Name')+'.'+t.get('Name')]=U(t.get('TriggerText'))
    for pu in fm.findall(NS+'ProgramUnit'): d['PU.'+pu.get('Name')]=U(pu.get('ProgramUnitText'))
    return d
a=load(sys.argv[1]); b=load(sys.argv[2])
for k in sorted(a):
    if not a[k].strip(): continue
    if k in b and b[k].split()==a[k].split(): st='SAME'
    elif k in b: st='DIFF'
    else: st='NEW'
    print(st, k, len(a[k].splitlines()))
if len(sys.argv)>3:
    import difflib
    for k in sys.argv[3].split(','):
        print('=====',k)
        print('\n'.join(difflib.unified_diff(b.get(k,'').splitlines(),a.get(k,'').splitlines(),'1170','1210',lineterm='',n=1)) if k in b else a[k])
