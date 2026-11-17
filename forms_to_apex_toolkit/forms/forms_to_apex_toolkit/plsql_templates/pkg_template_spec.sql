-- =============================================================================
-- Package     : pkg_<form>          (replace <form>, <block>, <item> everywhere)
-- Source form : <FORM>.fmb (Oracle Forms 12c)
-- Target      : Oracle APEX 21.2 / Oracle Database 12.1.0.2
-- Author      : <author>
-- Created     : <YYYY-MM-DD>
-- Version     : 1.0.0
-- Purpose     : Business logic of the form, organised like the form itself:
--               one section per block, members named <object>_<trigger_abbr>
--               (see docs/apex_structure_standard.md section 5).
-- Rules       : every identifier <= 30 bytes (DB 12.1.0.2); no qualified expressions (18c).
-- History     : <YYYY-MM-DD> <author> 1.0.0 Initial migration
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PACKAGE pkg_<form>
AUTHID DEFINER
AS
    c_version CONSTANT VARCHAR2(10) := '1.0.0';

    -- Record per base-table block (= Forms block record)
    SUBTYPE t_<block>_rec IS <base_table>%ROWTYPE;

    -- =========================================================================
    -- FORM LEVEL                                   (Forms: form-level triggers)
    -- =========================================================================
    -- Source: <FORM>.WHEN-NEW-FORM-INSTANCE   APEX: Process "WHEN-NEW-FORM-INSTANCE" (Before Header)
    PROCEDURE wnfi;

    -- Source: <FORM>.PRE-COMMIT                APEX: Process "PRE-COMMIT" (before DML processes)
    -- PROCEDURE pre_commit;

    -- =========================================================================
    -- BLOCK <BLOCK>                                (Forms: block + item triggers)
    -- =========================================================================
    -- Source: <BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM
    -- APEX  : Validation "<BLOCK>.<ITEM>.WHEN-VALIDATE-ITEM" (PL/SQL Function Body returning Error Text)
    --         RETURN pkg_<form>.<item>_wvi(:P<page>_<ITEM>);
    FUNCTION <item>_wvi (p_value IN VARCHAR2) RETURN VARCHAR2;

    -- Source: <BLOCK>.WHEN-VALIDATE-RECORD     APEX: Validation "<BLOCK>.WHEN-VALIDATE-RECORD"
    PROCEDURE <block>_wvr (p_rec IN t_<block>_rec);

    -- Source: <BLOCK>.WHEN-CREATE-RECORD       APEX: item defaults / computation
    PROCEDURE <block>_wcr (p_rec IN OUT NOCOPY t_<block>_rec);

    -- Source: <BLOCK>.PRE-INSERT / PRE-UPDATE / PRE-DELETE
    -- APEX  : Processes "<BLOCK>.PRE-INSERT" ... placed BEFORE Automatic Row Processing
    PROCEDURE <block>_pre_ins (p_rec IN OUT NOCOPY t_<block>_rec);
    PROCEDURE <block>_pre_upd (p_rec IN OUT NOCOPY t_<block>_rec);
    PROCEDURE <block>_pre_del (p_rec IN t_<block>_rec);

    -- Source: <BLOCK>.POST-QUERY               APEX: column in region SQL / view
    FUNCTION <block>_post_qry (p_lookup_id IN NUMBER) RETURN VARCHAR2;

    -- Source: <BLOCK>.<BUTTON>.WHEN-BUTTON-PRESSED
    -- APEX  : Button <BUTTON> + Process "<BLOCK>.<BUTTON>.WHEN-BUTTON-PRESSED"
    -- PROCEDURE <button>_wbp (p_<pk> IN NUMBER);

    -- =========================================================================
    -- PROGRAM UNITS                                (Forms: Program Units node, same names)
    -- =========================================================================
    -- PROCEDURE <program_unit_name> (...);
    -- FUNCTION  <program_unit_name> (...) RETURN ...;

END pkg_<form>;
/
SHOW ERRORS
