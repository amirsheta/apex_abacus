import sys, xml.etree.ElementTree as ET, html
ns={'f':'http://xmlns.oracle.com/Forms'}
fm=ET.parse(sys.argv[1]).getroot().find('f:FormModule',ns)
U=lambda s: html.unescape(s or '').replace('\r','')
out=open('code_dump.txt','w')
def w(h,txt): out.write(f"\n===== {h} =====\n{U(txt)}\n")
for tr in fm.findall('f:Trigger',ns): w('FORM.'+tr.get('Name'),tr.get('TriggerText'))
for b in fm.findall('f:Block',ns):
  for tr in b.findall('f:Trigger',ns): w(b.get('Name')+'.'+tr.get('Name'),tr.get('TriggerText'))
  for it in b.findall('f:Item',ns):
    for tr in it.findall('f:Trigger',ns): w(b.get('Name')+'.'+it.get('Name')+'.'+tr.get('Name'),tr.get('TriggerText'))
for p in fm.findall('f:ProgramUnit',ns): w('PU '+p.get('Name'),p.get('ProgramUnitText'))
