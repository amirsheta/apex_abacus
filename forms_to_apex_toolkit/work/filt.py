import re,hashlib
txt=open('code_dump.txt').read()
parts=re.split(r'\n===== (.+?) =====\n',txt)[1:]
skipPU={'CHECK_TIMEOUT','MOUSE_CLICK','TOGGEL_WND','CHECK_EDI_MSG_LOV','CHECK_EDI_MSG_TIMER','CHECK_EDI_ROLE_ID','EDI_MSG_LOV','FOR_EDI_MSG','RETURN_MSG','TURN_MSG','WHEN_TIMER_EXPIRED_MSG','DEV_VERSIONS'}
seen={}
o=open('biz.txt','w')
for h,b in zip(parts[::2],parts[1::2]):
  if re.match(r'(LSIDE|TITLE|EDI_MSG)\.',h): continue
  if h.startswith('PU ') and h[3:] in skipPU: continue
  k=hashlib.md5(re.sub(r'\s+',' ',b).encode()).hexdigest()
  if k in seen: o.write(f"\n===== {h} ===== (SAME AS {seen[k]})\n"); continue
  seen[k]=h
  b=re.sub(r'\n\s*\n+','\n',b)
  o.write(f"\n===== {h} =====\n{b}\n")
