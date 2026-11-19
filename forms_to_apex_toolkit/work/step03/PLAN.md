# Step 03 (revision 2) — IMPR1110 page design — progress

Started 2026-11-19. Standard: CLAUDE.md §4a–§4c, §8; docs/f345_reference_standard.md; prompt 03.
Previous version: rollback/IMPR1110/step03_rev1/ (spec + registry v2.1, AJAX / JavaScript design).

Build:
    python3 -I work/step02/build_package.py     # package (006) -> entries.json
    python3 -I work/step03/build_spec.py        # gen_*.md, page_design.json, registry/IMPR1110_registry.sql
    (assemble) spec_part1 + gen_items + spec_part2 + gen_validations + spec_part3 + gen_processes + spec_part4
               + gen_computations + spec_part5 + gen_das + spec_part6 + gen_trace + spec_part7
               -> analysis/IMPR1110/IMPR1110_apex_page_spec.md
    python3 -I work/step03/self_check.py        # binds, members, JS <= 3 lines, names

- [x] design decisions (Form region ROWID, P0_PAGE_PK = ROWID, flags for runtime read-only rules, Hijri text)
- [x] package changes 005 -> 006 (DATE as text, P0_PAGE_PK_CHECK ROWID, IMPORTER_ROW_ID, READ_ONLY_FLAGS 14)
- [x] spec tables generated, prose written, assembled
- [x] registry v3.0 (668 rows)
- [x] self-check: no findings (step 02 and step 03)
