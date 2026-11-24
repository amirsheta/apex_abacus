import sys, difflib
sys.path.insert(0,'work/IMPR1116/tmp')
exec(open('work/IMPR1116/tmp/diff_trg.py').read().split('a=load')[0])
a=load('forms/IMPR/IMPR1116_fmb.xml'); b=load('forms/IMPR/IMPR1120_fmb.xml')
for k in sys.argv[1:]:
    print('=====',k)
    if k in b:
        print('\n'.join(difflib.unified_diff(b[k].splitlines(),a[k].splitlines(),'1120','1116',lineterm='',n=1)))
    else: print(a[k])
