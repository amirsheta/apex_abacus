import re,sys,glob,os,json
KW={'COMMIT':r'\bCOMMIT(_FORM)?\b','DML':r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM)\b','TEXT_IO':r'\bTEXT_IO\.','HOST':r'\bHOST\s*\(','TIMER':r'\b(CREATE|DELETE|FIND)_TIMER\b','CALL_FORM':r'\b(CALL_FORM|OPEN_FORM|NEW_FORM)\b','RUN_PRODUCT':r'\bRUN_PRODUCT\b|RUN_REPORT_OBJECT','SHOW_DOC':r'WEB\.SHOW_DOCUMENT','FORMS_DDL':r'\bFORMS_DDL\b','EXEC_SQL':r'\bEXEC_SQL\.','ORA_FFI':r'\bORA_FFI\.','WEBUTIL':r'\bWEBUTIL\w*\.|CLIENT_\w+\.','SET_PROP':r'\bSET_\w+_PROPERTY\b','DBMS':r'\bDBMS_\w+','ALERT':r'\bSHOW_ALERT\b','GLOBAL':r':?GLOBAL\.\w+','EXIT_FORM':r'\bEXIT_FORM\b','DO_KEY':r'\bDO_KEY\b','SYNCHRONIZE':r'\bSYNCHRONIZE\b'}
def split(txt):
    # find package bodies then procedure/function starts
    out=[];pkg=None
    lines=txt.split('\n')
    cur=None;buf=[]
    for i,l in enumerate(lines):
        m=re.match(r'\s*PACKAGE\s+BODY\s+(\S+)',l,re.I)
        if m: 
            if cur: out.append((cur,buf))
            pkg=m.group(1).upper();cur=None;buf=[];continue
        m2=re.match(r'\s*PACKAGE\s+(\S+)',l,re.I)
        if m2 and not m: 
            if cur: out.append((cur,buf))
            pkg=None;cur=None;buf=[];continue
        m=re.match(r'\s*(PROCEDURE|FUNCTION)\s+(\w+[\$\w]*)',l,re.I)
        if m and pkg:
            if cur: out.append((cur,buf))
            cur=(pkg,m.group(2).upper(),i+1);buf=[]
        if cur: buf.append(l)
    if cur: out.append((cur,buf))
    return out
res=[]
for f in sorted(glob.glob('/home/ubuntu/work/libs/*.txt')):
    t=open(f,errors='replace').read()
    for (pkg,name,ln),b in split(t):
        code='\n'.join(x for x in b if not x.strip().startswith('--'))
        hits={k:len(re.findall(v,code,re.I)) for k,v in KW.items()}
        tabs=sorted(set(x.upper() for x in re.findall(r'\b(?:FROM|INTO|UPDATE|JOIN)\s+([A-Z_][A-Z0-9_\$#\.]+)',code,re.I))-{'DUAL'})
        res.append(dict(lib=os.path.basename(f)[:-4],pkg=pkg,name=name,line=ln,lines=len(b),hits={k:v for k,v in hits.items() if v},tables=tabs[:15]))
json.dump(res,open('/home/ubuntu/work/libscan.json','w'),indent=0)
for r in res:
    if r['lib']=='CIC_LIB' and r['pkg']=='NIB': print(r['name'],r['line'],r['lines'],r['hits'],r['tables'])
print(len(res))
