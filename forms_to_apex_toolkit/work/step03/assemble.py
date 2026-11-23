"""assemble analysis/IMPR1110/IMPR1110_apex_page_spec.md from the written parts and the generated tables.
Usage: python3 -I work/step03/assemble.py   (after work/step03/build_spec.py)"""
d = 'work/step03/'
order = ['spec_part1.md', 'gen_items.md', 'spec_part2.md', 'gen_validations.md', 'spec_part3.md', 'gen_processes.md',
         'spec_part4.md', 'gen_computations.md', 'spec_part5.md', 'gen_das.md', 'spec_part6.md', 'gen_trace.md', 'spec_part7.md']
text = ''.join(open(d + f, encoding='utf-8').read() for f in order)
text = text.replace('(about 300 lines) and 3 AJAX callbacks', '(396 lines) and 3 AJAX callback processes')
open('analysis/IMPR1110/IMPR1110_apex_page_spec.md', 'w', encoding='utf-8', newline='\n').write(text)
print(len(text.splitlines()), 'lines')
