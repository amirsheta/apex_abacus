# Migration Checklist — Oracle Forms 12c → APEX 21.2

## 1. Pre-migration
### Environment setup
- [ ] APEX 21.2.x installed in DEV/TEST/PROD (`select version_no from apex_release`)
- [ ] ORDS configured; Universal Theme 42 available
- [ ] `scripts/setup_apex_workspace.sql` run by DBA (schema `FORMS_MIGRATION`, workspace)
- [ ] Database version confirmed 12.1.0.2 (`select version from v$instance`)
- [ ] `scripts/create_migration_registry.sql` and `plsql_templates/pkg_forms_compat.sql` installed; error handling function set
- [ ] Forms-mirror standard (`docs/apex_structure_standard.md`) agreed by the team; page ranges allocated in `MIG_FORM_REGISTRY`
- [ ] utPLSQL v3 installed in DEV/TEST (version that supports DB 12.1)
- [ ] Git repository created from this toolkit; Claude Code installed; `CLAUDE.md` reviewed
- [ ] Forms 12c Builder host available for `frmf2xml`; `FORMS_PATH` includes all `.olb/.pll`
### Inventory
- [ ] All `.fmb/.pll/.olb/.mmb` collected into `input/fmb/` (versions confirmed against production)
- [ ] `scripts/convert_forms_to_xml.sh input/fmb ./output` — 0 failures
- [ ] `.pll` converted to text (`frmcmp_batch module=X.pll module_type=LIBRARY script=YES`)
- [ ] Prompt 01 run per form; complexity + risk list consolidated into a master spreadsheet
- [ ] Shared libraries migrated first as `pkg_lib_<name>`
- [ ] Reports (`.rdf`) dependencies identified and target reporting tool decided
### Stakeholder sign-off
- [ ] Scope, form priority order and wave plan approved
- [ ] Authentication/authorization approach approved (DB / LDAP / SSO)
- [ ] UI changes accepted (web UX vs Forms keyboard behaviour)
- [ ] Business owner and UAT testers named per form

## 2. Per-form migration steps
| # | Step | Deliverable | Done |
|---|---|---|---|
| 1 | Analysis (prompt 01) | `<form>_inventory.md` reviewed, open questions answered | [ ] |
| 2 | Logic extraction (prompt 02) | package `<FORM>` spec/body compile without errors (f345 naming, no `pkg_` / `AI_`); extraction report reviewed | [ ] |
| 3 | Schema changes (if any) | `migration/NNN_*.sql` + `_rollback.sql`, DBA-approved | [ ] |
| 4 | APEX page design (prompt 03) | `<form>_apex_page_spec.md` approved; traceability matrix 100% | [ ] |
| 5 | APEX build (prompt 04 or manual) | Export imported in DEV, reviewed in Page Designer, Advisor clean | [ ] |
| 6 | Test (prompt 05) | utPLSQL green; data compare all PASS | [ ] |
| 7 | UAT | `uat_checklist_<form>.md` signed by business owner | [ ] |
| 8 | Deploy | App export + DB scripts deployed to TEST → PROD via release script; rollback tested | [ ] |

## 3. Post-migration
- [ ] Forms module disabled in menu / Forms server (keep read-only fallback for agreed period)
- [ ] Decommission Forms after sign-off period; archive `.fmb` sources
- [ ] User training (quick reference: Forms key → APEX button), help pages
- [ ] Monitoring: APEX Activity Log, `apex_workspace_activity_log`, error log via error handling function
- [ ] Performance review of slow pages (Debug, `apex_debug`)
- [ ] Backup of APEX application exports in Git after every release

## 4. Risk register
| Risk | Impact | Mitigation |
|---|---|---|
| Logic hidden in `.pll`/subclassed `.olb` not exported | Missing behaviour | Convert libraries first; FORMS_PATH set; mark MISSING SOURCE |
| `HOST`, `TEXT_IO`, OLE, Java beans, timers | No direct web equivalent | Redesign: DBMS_SCHEDULER, File Browse, JS timers — decide early |
| POST-QUERY per-row lookups | Slow reports | Move to JOINs/views |
| Forms implicit locking & commit model | Lost updates | Rely on APEX optimistic locking (checksums); review ON-LOCK |
| `:GLOBAL` cross-form state | Wrong data between pages | Application Items + explicit URL parameters |
| Users expect keyboard-driven workflow | Low acceptance | IG keyboard support, training, early demos |
| Generated APEX export invalid for instance | Import failures | Use reference export; import to DEV; manual review |
| Features beyond 21.2 suggested by AI | Unimportable code | CLAUDE.md version lock; review |
| Reports (`RUN_REPORT_OBJECT`) | Missing output | Choose BI Publisher / APEX Office Print / PL/PDF |
| Large forms exceed Claude context | Incomplete analysis | One form per session; chunked XML reads |
