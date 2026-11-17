import sys, xml.etree.ElementTree as ET, html
ns={'f':'http://xmlns.oracle.com/Forms'}
t=ET.parse(sys.argv[1]); r=t.getroot()
fm=r.find('f:FormModule',ns)
def a(e,k): return e.get(k)
print("FORM",fm.get('Name'),fm.get('Title'))
for b in fm.findall('f:Block',ns):
    print("\nBLOCK",{k:v for k,v in b.attrib.items() if k in('Name','QueryDataSourceName','DMLDataName','RecordsDisplayCount','DatabaseBlock','WhereClause','OrderByClause','QueryAllowed','InsertAllowed','UpdateAllowed','DeleteAllowed','NextNavigationBlockName','Comment')})
    for tr in b.findall('f:Trigger',ns):
        print("  BTRG",tr.get('Name'),len((tr.get('TriggerText') or '').splitlines()))
    for it in b.findall('f:Item',ns):
        d={k:v for k,v in it.attrib.items() if k in('Name','ItemType','DataType','MaximumLength','ColumnName','DatabaseItem','Required','Prompt','LovName','CanvasName','TabPageName','Visible','InitializeValue','FormatMask','QueryOnly','UpdateAllowed','InsertAllowed','Enabled','CopyValueFromItem','Label','CalculateMode','Formula','SummaryFunction','Hint')}
        print("  ITEM",d)
        for tr in it.findall('f:Trigger',ns):
            print("     ITRG",tr.get('Name'),len((tr.get('TriggerText') or '').splitlines()))
        for le in it.findall('f:ListItemElement',ns):
            print("     LIST",le.get('Name'),le.get('Value'))
print()
for tr in fm.findall('f:Trigger',ns): print("FTRG",tr.get('Name'),len((tr.get('TriggerText') or '').splitlines()))
for p in fm.findall('f:ProgramUnit',ns): print("PU",p.get('Name'),p.get('ProgramUnitType'),len((p.get('ProgramUnitText') or '').splitlines()))
for x in fm.findall('f:AttachedLibrary',ns): print("LIB",x.get('Name'),x.get('LibraryLocation'))
for x in fm.findall('f:Alert',ns): print("ALERT",x.get('Name'),x.get('AlertStyle'),x.get('AlertMessage'),x.get('Button1Label'),x.get('Button2Label'))
for x in fm.findall('f:RecordGroup',ns): print("RG",x.get('Name'),x.get('RecordGroupType'),(x.get('RecordGroupQuery') or '').replace('\n',' '))
for x in fm.findall('f:LOV',ns):
    print("LOV",x.get('Name'),x.get('RecordGroupName'),x.get('Title'))
    for m in x.findall('f:LOVColumnMapping',ns): print("   MAP",m.get('Name'),m.get('ReturnItem'),m.get('Title'),m.get('DisplayWidth'))
for x in fm.findall('f:Canvas',ns): print("CANVAS",x.get('Name'),x.get('CanvasType'),x.get('WindowName'))
for x in fm.findall('f:Window',ns): print("WIN",x.get('Name'),x.get('Title'))
for x in fm.findall('f:ModuleParameter',ns): print("PARAM",x.get('Name'),x.get('ParameterDataType'),x.get('ParameterInitializeValue'))
for x in fm.findall('f:Report',ns): print("REPORT",x.attrib)
