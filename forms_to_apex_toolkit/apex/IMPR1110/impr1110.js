/* =============================================================================
 * File        : apex/IMPR1110/impr1110.js  (upload as Static Application File impr1110.js;
 *               the page references #APP_FILES#impr1110#MIN#.js - also upload a minified
 *               impr1110.min.js or change the reference to #APP_FILES#impr1110.js)
 * Source form : IMPR1110.fmb - client part of the item / record triggers (page 1110)
 * Target      : Oracle APEX 21.2 (apex.server, apex.item, apex.message, apex.page, apex.navigation)
 * Author      : Claude Code
 * Created     : 2026-11-18
 * Version     : 1.1.0 (step 04, f345 standard: toolbar on page 0, search page 111001,
 *               mobile page 111002; previous version rollback/IMPR1110/impr1110_js_v1.js)
 * Purpose     : ONE place for the behaviour the Dynamic Actions of page 1110 call, like a Forms
 *               library. No business rules here: every rule runs on the server in
 *               IMPR1110 (-> pkg_impr1110_apx / pkg_impr1110). This file only
 *                 - calls the AJAX processes IMPR1110_ITEM / IMPR1110_CONFIRM / IMPR1110_FUN,
 *                 - writes the returned item values into the page,
 *                 - applies the UI state (pkg_impr1110.ui_json): enable/disable, required,
 *                   show/hide, focus, messages, function menu,
 *                 - asks the Confirm questions and sends the answers back.
 *               The server re-checks everything at SAVE (validations "<ITEM> VALIDATION"), so nothing
 *               here can be bypassed to save invalid data.
 * Status      : NOT TESTED (REVIEW BEFORE IMPORT).
 * ============================================================================= */
/* global apex, $v */
window.impr1110 = (function ($) {
    "use strict";

    var PFX = "P1110_",
        REGION = "#IMPORTERS",
        invalid = {},        // Forms item that failed validation -> the cursor must return to it
        funOff = {},         // function codes switched off by ADJ_FUNS (TMPLT.DISABLE_FUN)
        lovPick = {},        // item whose value was just chosen from the Popup LOV (x05 = LOV)
        opts = {},
        queue = $.Deferred().resolve().promise();   // calls run in event order, one at a time

    var TXT = {
        susp: null,
        newRec: "يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟",
        del: "هل أنت متأكد من عملية الحذف",
        invalid: "يجب تصحيح قيمة الحقل قبل المتابعة",
        // TODO: real text = Forms alert CFG_ASK_COMMIT (CIC_OLB) - wording to confirm
        unsaved: "توجد تغييرات لم يتم حفظها، هل تريد المتابعة بدون حفظ؟",
        funOff: "هذه الوظيفة غير متاحة حالياً",
        // TODO: MISSING page 1113 (SUPPORT_ENTRY) - remove when the page exists
        noSupport: "شاشة خطاب الدعم (SUPPORT_ENTRY - صفحة 1113) لم تُنشأ بعد",
        noScreen: "الشاشة IMPR1115 لم تُحوّل بعد"
    };

    // ------------------------------------------------------------------ helpers
    function pi(item) { return PFX + item; }

    function itemOf(name) {
        var it = apex.item(name);
        return (it && it.node) ? it : null;
    }

    function enqueue(fn) {
        queue = queue.then(fn, fn);
        return queue;
    }

    function pageError(text, item) {
        apex.message.clearErrors();
        apex.message.showErrors([{
            type: "error",
            location: item ? ["inline", "page"] : ["page"],
            pageItem: item ? pi(item) : undefined,
            message: text,
            unsafe: false
        }]);
    }

    function confirmAsk(text) {            // -> promise of 1 (yes) / 2 (no), like ALERT_BUTTON1/2
        var d = $.Deferred();
        apex.message.confirm(text, function (ok) { d.resolve(ok ? 1 : 2); });
        return d.promise();
    }

    // Writes the values returned by the server. Change events are suppressed so a value set by
    // a trigger does not fire that item's trigger again (Forms does not fire WHEN-VALIDATE-ITEM
    // for values assigned in code).
    function setItems(items) {
        if (!items) { return; }
        Object.keys(items).forEach(function (name) {
            var it = itemOf(name), val = items[name] === null ? "" : String(items[name]);
            if (!it || name === "P1110_ROW_ID") { return; }
            if (it.getValue() !== val) {
                it.setValue(val, val, true);
            }
        });
    }

    function lovButton(item) {
        return $("#" + pi(item) + "_lov_btn, #" + pi(item) + "_CONTAINER .a-Button--popupLOV");
    }

    function setRequired(name, on) {
        var it = itemOf(name);
        if (!it) { return; }
        if (typeof it.setRequired === "function") {   // not documented for 21.2 - see import_notes
            it.setRequired(on);
        } else {
            $("#" + name).prop("required", on);
        }
        $("#" + name + "_CONTAINER").toggleClass("is-required", on);
    }

    // ------------------------------------------------------------------ UI state (ui_json)
    function applyUi(ui) {
        var commit = false;
        if (!ui) { return; }
        (ui.items || []).forEach(function (e) {
            var on = e.value === true, name, base;
            if (e.item === "IMPORTERS") {
                if (e.prop === "REQUERY" && on) { apex.page.submit({ request: "QUERY", showWait: true }); }
                if (e.prop === "DO_COMMIT" && on) { commit = true; }
                if (e.prop === "BLOCK_UPDATE_ONLY") { toolbar("CREATE").add(toolbar("DELETE")).toggle(!on); }
                return;
            }
            name = pi(e.item);
            if (!itemOf(name)) {
                // CITY_CODE_OF_ID2, CITY_CODE2 ... = Forms LOV buttons -> the Popup LOV button
                base = e.item.replace(/2$/, "");
                if (base !== e.item && (e.prop === "ENABLED" || e.prop === "ENTRABLE")) {
                    lovButton(base).prop("disabled", !on);
                } else if (base !== e.item && e.prop === "VISIBLE") {
                    lovButton(base).toggle(on);
                }
                return;
            }
            switch (e.prop) {
            case "ENTRABLE":
            case "ENABLED":
                if (on) { apex.item(name).enable(); } else { apex.item(name).disable(); }
                break;
            case "REQUIRED":
                setRequired(name, on);
                break;
            case "VISIBLE":
                if (on) { apex.item(name).show(); } else { apex.item(name).hide(); }
                break;
            case "OPEN_LOV":
                if (on) { lovButton(e.item).first().trigger("click"); }
                break;
            default:                 // VALID: the server re-validates the item at SAVE
                break;
            }
        });
        (ui.funs || []).forEach(function (f) { funOff[f.fun] = !f.enabled; });
        if (ui.messages && ui.messages.length) {
            apex.message.showPageSuccess(ui.messages.map(apex.util.escapeHTML).join("<br>"));
        }
        if (ui.focus && itemOf(pi(ui.focus))) {
            apex.item(pi(ui.focus)).setFocus();
        }
        if (commit) {
            apex.page.submit({ request: saveRequest(), showWait: true });
        }
    }

    // ------------------------------------------------------------------ page 0 toolbar (f345)
    // The toolbar buttons live on the global page (region P0_ACTIONS) and have no static ids.
    // CREATE and SAVE share the class cg-b-save; only one of them is rendered (P0_PAGE_PK).
    function toolbar(request) {
        if (request === "DELETE") { return $("#P0_ACTIONS .cg-b-del"); }
        if (request === "CREATE") { return $v("P0_PAGE_PK") ? $() : $("#P0_ACTIONS .cg-b-save"); }
        if (request === "SAVE")   { return $v("P0_PAGE_PK") ? $("#P0_ACTIONS .cg-b-save") : $(); }
        return $();
    }

    // CREATE inserts a new record, SAVE updates the record in P0_PAGE_PK (f345 toolbar requests)
    function saveRequest() {
        return $v("P0_PAGE_PK") ? "SAVE" : "CREATE";
    }

    // ------------------------------------------------------------------ server calls
    function handle(item, data) {
        if (data && data.error) {
            if (item) {
                invalid[item] = true;
                pageError(data.error, item);
                if (itemOf(pi(item))) { apex.item(pi(item)).setFocus(); }
            } else {
                pageError(data.error);
            }
            return { ok: false };
        }
        if (item) { delete invalid[item]; }
        apex.message.clearErrors();
        setItems(data.items);
        applyUi(data.ui);
        return { ok: true, data: data };
    }

    function ajax(process, x, item) {
        x.pageItems = REGION + " :input";
        return apex.server.process(process, x, { dataType: "json" }).then(
            function (data) { return handle(item, data); },
            function (jq, status, err) { pageError(err || status, item); return { ok: false }; }
        );
    }

    // IMPR1110_ITEM: x01 item, x02 event, x03/x04 Confirm answers, x05 LOV marker
    function run(item, evt, a1, a2, x05) {
        return ajax("IMPR1110_ITEM", {
            x01: item || "", x02: evt, x03: a1 || "", x04: a2 || "", x05: x05 || ""
        }, item);
    }

    function confirmText(code) {
        return apex.server.process("IMPR1110_CONFIRM", { x01: code, pageItems: REGION + " :input" },
                                  { dataType: "json" })
            .then(function (d) { return (d && d.text) || ""; });
    }

    // BUS_ID_TYPE_CD options depend on IMPR_TYPE_CD (LOV_IMPR_TYPE_BUS_ID reads session state)
    function refreshBusIdType() {
        var it = itemOf(pi("BUS_ID_TYPE_CD")), keep;
        if (!it || typeof it.refresh !== "function") { return; }
        keep = it.getValue();
        $("#" + pi("BUS_ID_TYPE_CD")).one("apexafterrefresh", function () { it.setValue(keep, null, true); });
        it.refresh();
    }

    // ------------------------------------------------------------------ public API (DAs)
    // DA 1 IMPORTERS.UI-STATE (page load)
    function init(o) {
        var raw = $v(pi("UI_STATE")), next = $v(pi("NEXT_FUN"));
        opts = o || {};
        $(REGION).on("mousedown keydown", ".a-Button--popupLOV", function () {
            lovPick[this.id.replace(/_lov_btn$/, "").replace(PFX, "")] = true;
        });
        try { applyUi(raw ? JSON.parse(raw) : {}); } catch (e) { apex.debug.error("impr1110.init", e); }
        apex.item(pi("UI_STATE")).setValue("", null, true);   // never re-applied from a stale submit
        if (next) {
            apex.item(pi("NEXT_FUN")).setValue("", null, true);
            fun(next);
        }
    }

    // DA 2 IMPORTERS.<ITEM>.WHEN-VALIDATE-ITEM (+ DA 3 confirm for BUS_ID, DA 4 re-query via REQUERY)
    function validate(item) {
        return enqueue(function () {
            var x05 = lovPick[item] ? "LOV" : "";
            delete lovPick[item];
            if (item === "BUS_ID") {
                return confirmText("SUSP").then(function (t) {
                    return t ? confirmAsk(t) : 1;
                }).then(function (ans) {
                    // x03 = alert 9-120 answer (not asked: Forms default button 1), x04 = SUSP answer
                    return run(item, "VALIDATE", "", ans, x05);
                });
            }
            return run(item, "VALIDATE", "", "", x05).then(function (r) {
                if (r.ok && item === "IMPR_TYPE_CD") { refreshBusIdType(); }
                return r;
            });
        });
    }

    // DA 5 IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL (pair returned) -> BUS_ID_TYPE_CD
    function lovReturn(item) {
        return enqueue(function () { return run(item, "LOV_RET"); });
    }

    // DA 6 WHEN-NEW-ITEM-INSTANCE
    function wnii(item) {
        return enqueue(function () { return run(item, "WNII"); });
    }

    // DA 7 WHEN-LIST-CHANGED
    function listChanged(item) {
        return enqueue(function () { return run(item, "WLC"); });
    }

    // DA 8 KEY-NEXT-ITEM (Tab / Enter): net effect of the trigger = GO_ITEM(target)
    function keyNext(ev, target) {
        if (ev && (ev.which === 9 || ev.which === 13) && !ev.shiftKey) {
            ev.preventDefault();
            apex.item(pi(target)).setFocus();
        }
    }

    function firstInvalid() {
        var k = Object.keys(invalid);
        return k.length ? k[0] : null;
    }

    // Commit from code (IMPR_MCI_SERVICE, DO_COMMIT): same path as the toolbar button
    function save() {
        apex.page.submit({ request: saveRequest(), showWait: true });
    }

    // DA "PRE-INSERT CONFIRM" (Before Page Submit) = TOOLBAR.SAVE + IMPORTERS.PRE-INSERT confirm.
    // The page 0 buttons CREATE / SAVE submit directly; this stops the submit while an item is
    // still invalid, and asks the PRE-INSERT question before a CREATE. DELETE (confirm) and
    // CLEAR (redirect) are handled by page 0 itself.
    var confirmed = false;
    function beforeSubmit(request) {
        var bad;
        if (request !== "CREATE" && request !== "SAVE") { return; }
        if (confirmed) { confirmed = false; return; }
        bad = firstInvalid();
        if (bad) {
            apex.event.gCancelFlag = true;
            pageError(TXT.invalid, bad);
            apex.item(pi(bad)).setFocus();
            return;
        }
        if (request === "CREATE" && opts.confirmNew) {
            apex.event.gCancelFlag = true;
            confirmAsk(TXT.newRec).then(function (ans) {
                if (ans === 1) {
                    confirmed = true;
                    apex.page.submit({ request: "CREATE", showWait: true });
                }
            });
        }
    }

    // DA 12 IMPORTERS.WHEN-NEW-RECORD-INSTANCE after a function set :PARAMETER.CODE
    function wnri() {
        return confirmText("WNRI").then(function (t) {
            return t ? confirmAsk(t) : 1;
        }).then(function (ans) {
            return run(null, "WNRI", ans);
        });
    }

    function runFun(code, answer) {
        return ajax("IMPR1110_FUN", { x01: code, x02: answer || "" }, null).then(function (r) {
            if (r.ok && r.data.items && r.data.items.P1110_CODE) {
                return wnri().then(function () { return r; });
            }
            return r;
        });
    }

    // DA "<CODE> FUNCTION" (custom event <CODE> fired by the f345 "Page Functions" list in
    // region FUNCS) = TMPLT EXECUTE_FUNCTION -> EXEC_FUNS
    function fun(code) {
        if (funOff[code]) {
            pageError(TXT.funOff);
            return;
        }
        enqueue(function () {
            switch (code) {
            case "IMPR1110F1":
            case "IMPR1110F2":
            case "IMPR1110F3":
            case "IMPR1110F5":
                // CALL_FORM('SUPPORT_ENTRY') then EXEC_FUNS - TODO: MISSING page 1113
                pageError(TXT.noSupport);
                return;
            case "IMPR1115_SCR":
                pageError(TXT.noScreen);            // TODO: link when IMPR1115 is converted
                return;
            case "IMPR_MCI_SERVICE":
                if (apex.page.isChanged()) {         // Forms commits the record first
                    apex.item(pi("NEXT_FUN")).setValue(code, null, true);
                    save();
                    return;
                }
                return confirmText("UPD_IMPR").then(function (t) {
                    return t ? confirmAsk(t) : 1;
                }).then(function (ans) { return runFun(code, ans); });
            case "IMPR1110_MOB":
                return runFun(code).then(function (r) {
                    var url = $v(pi("URL_MOB"));
                    if (r.ok && url) { apex.navigation.redirect(url); }
                });
            default:
                return runFun(code);
            }
        });
    }

    // The search page 111001 returns the record through P0_PAGE_PK (link column, f345), so no
    // close handler is needed for it.

    // DA "DIALOG CLOSED": page 111002 (LOV_UPDATE_IMPR_MOBILE) closed
    function dialogClosed(data) {
        var pg = data && String(data.dialogPageId);
        if (pg === "111002") {
            enqueue(function () { return runFun("IMPR1110_MOB_RET"); });
        }
        // page 1113 (SUPPORT_ENTRY): runFun(<code>) after the dialog - TODO when the page exists
    }

    return {
        init: init, validate: validate, lovReturn: lovReturn, wnii: wnii, listChanged: listChanged,
        keyNext: keyNext, save: save, beforeSubmit: beforeSubmit, fun: fun,
        dialogClosed: dialogClosed, applyUi: applyUi
    };
})(apex.jQuery);
