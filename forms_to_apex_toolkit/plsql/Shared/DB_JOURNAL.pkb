CREATE OR REPLACE PACKAGE BODY JOURNAL.DB_JOURNAL IS
	journalingOn			BOOLEAN:=FALSE;
	suppSrceCd				number(3):=null;
	suppTitleCd				number(2):=null;
	suppLetrNo				varchar2(50):=null;
	suppLetrDt				date:=null;
	oldkey					  varchar2(200):=null ;
	--------------------------
	procedure journaling_on(supp_srce_cd number,supp_title_cd number,supp_letr_no varchar2,supp_letr_dt date) is
	begin
		journalingOn:=true;
		suppSrceCd:=supp_srce_cd;
		suppTitleCd:=supp_title_cd;
		suppLetrNo:=supp_letr_no;
		suppLetrDt:=supp_letr_dt;
	end;
	--------------------------
	procedure journaling_off is
	begin
		journalingOn:=false;
		suppSrceCd:=null;
		suppTitleCd:=null;
		suppLetrNo:=null;
		suppLetrDt:=null;
	end;
	--------------------------
	function is_journaling_on return boolean is
	begin
		return journalingOn;
	end;
	--------------------------
	procedure get_journaling_params(supp_srce_cd in out number,supp_title_cd in out number,supp_letr_no in out varchar2,supp_letr_dt  in out date , Old_Key in out varchar2) is
	begin
		supp_srce_cd:=suppSrceCd;
		supp_title_cd:=suppTitleCd;
		supp_letr_no:=suppLetrNo;
		supp_letr_dt:=suppLetrDt;
		Old_Key := oldkey;
	end;
	--------------------------
		procedure set_oldkey(oldkey_value varchar2)  is
		begin
		oldkey := oldkey_value ;
		end;
	--------------------------
		procedure clear_oldkey is
		begin
		oldkey := NULL ;
		end;
	--------------------------
	procedure create_stuff(schemaName varchar2,tableName varchar2) is
		triggerBody							long;
		triggerRec							sys.dba_triggers%ROWTYPE;
		badOp										boolean:=false;
		mrTriggerFound					boolean:=false;
		obejct_name_used				EXCEPTION;
		PRAGMA EXCEPTION_INIT(obejct_name_used,-955);
		column_exists_in_table	EXCEPTION;
		PRAGMA EXCEPTION_INIT(column_exists_in_table,-1430);
		constraint_exists_in_table	EXCEPTION;
		PRAGMA EXCEPTION_INIT(constraint_exists_in_table,-2275);
		firstRec								boolean;
		columnList							varchar2(2000):=null;
		oldColumnList						varchar2(2000):=null;
		newColumnList						varchar2(2000):=null;
		createStmt							long;
		tabColumnsRec						sys.dba_tab_columns%ROWTYPE;
		CURSOR tabColumnsCur IS SELECT * FROM sys.dba_tab_columns where owner=upper(schemaName) and table_name=upper(tableName) order by COLUMN_ID;
		dbms_error_text					varchar2(500);
	begin
		dbms_output.enable;
		--create the journal table
		begin
			execute immediate 'create table journal.' || tableName || '_jn as select * from ' || schemaName || '.' || tableName || ' where 1=2';
			exception
				when obejct_name_used then
					dbms_output.put_line('Table journal.' || tableName || '_JN already found');
					badOp:=true;
		end;
		--create the public synonym for the journal table
		begin
			execute immediate 'create public synonym ' || tableName || '_jn for journal.' || tableName || '_jn';
			exception
				when obejct_name_used then
					dbms_output.put_line('Public synonym for the table journal.' || tableName || '_JN already found');
					badOp:=true;
		end;
		--add new fields
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_OPERATION char(3)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_OPERATION already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_ORACLE_USER varchar2(30)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_ORACLE_USER already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_DATETIME date';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_DATETIME already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_NOTES varchar2(240)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_NOTES already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_APPLN varchar2(30)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_APPLN already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_SESSION number(38)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_SESSION already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add SUPP_SRCE_CD NUMBER(3)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field SUPP_SRCE_CD already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add SUPP_TITLE_CD NUMBER(2)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field SUPP_TITLE_CD already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add SUPP_LETR_NO varchar2(50)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field SUPP_LETR_NO already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add SUPP_LETR_DT date';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field SUPP_LETR_DT already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add JN_OLDKEY varchar2(200)';
			exception
				when column_exists_in_table then
					dbms_output.put_line('The field JN_OLDKEY already found on the table journal.' || tableName || '_JN');
					badOp:=true;
		end;
		--create constraints with SD_PORTS,SUPP_TITLES
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add constraint ' || tableName || '_SDP_FK FOREIGN KEY (PORT_CD) REFERENCES ' || schemaName || '.SD_PORTS (PORT_CD) DEFERRABLE INITIALLY immediate';
			exception
				when constraint_exists_in_table then
					dbms_output.put_line('The foreign key constraint ' || tableName || '_SDP_FK already found on the table journal.' || tableName || '_JN');
					badOp:=true;
				when others then
					dbms_error_text:=SQLERRM(SQLCODE);
					dbms_output.put_line('The foreign key constraint ' || tableName || '_SDP_FK could not be created on the table journal.' || tableName || '_JN' || ' due to ' || dbms_error_text);
					badOp:=true;
		end;
		begin
			execute immediate 'alter table journal.' || tableName || '_jn add constraint ' || tableName || '_ST_FK FOREIGN KEY (SUPP_TITLE_CD) REFERENCES ' || schemaName || '.SD_PORTS (SUPP_TITLE_CD) DEFERRABLE INITIALLY immediate';
			exception
				when constraint_exists_in_table then
					dbms_output.put_line('The foreign key constraint ' || tableName || '_ST_FK already found on the table journal.' || tableName || '_JN');
					badOp:=true;
				when others then
					dbms_error_text:=SQLERRM(SQLCODE);
					dbms_output.put_line('The foreign key constraint ' || tableName || '_ST_FK could not be created on the table journal.' || tableName || '_JN' || ' due to ' || dbms_error_text);
					badOp:=true;
		end;
		--create indexes
		begin
			execute immediate 'create index journal.' || tableName || '_SDP_I on journal.' || tableName || '_jn(PORT_CD)';
			exception
				when obejct_name_used then
					dbms_output.put_line('The foreign key constraint index journal.' || tableName || '_SDP_I already found on the table journal.' || tableName || '_JN');
					badOp:=true;
				when others then
					dbms_error_text:=SQLERRM(SQLCODE);
					dbms_output.put_line('The foreign key constraint index journal.' || tableName || '_SDP_I could not be created on the table journal.' || tableName || '_JN' || ' due to ' || dbms_error_text);
					badOp:=true;
		end;
		begin
			execute immediate 'create index journal.' || tableName || '_ST_I on journal.' || tableName || '_jn(SUPP_TITLE_CD)';
			exception
				when obejct_name_used then
					dbms_output.put_line('The foreign key constraint index journal.' || tableName || '_ST_I already found on the table journal.' || tableName || '_JN');
					badOp:=true;
				when others then
					dbms_error_text:=SQLERRM(SQLCODE);
					dbms_output.put_line('The foreign key constraint index journal.' || tableName || '_ST_I could not be created on the table journal.' || tableName || '_JN' || ' due to ' || dbms_error_text);
					badOp:=true;
		end;
		--alter man_rpl trigger and add the new journaling code
		firstRec:=true;
		OPEN tabColumnsCur;
		LOOP
			FETCH tabColumnsCur INTO tabColumnsRec;
			EXIT WHEN tabColumnsCur%NOTFOUND;
			if not firstRec then
				columnList:=columnList || ',';
				oldColumnList:=oldColumnList || ',';
				newColumnList:=newColumnList || ',';
			end if;
			columnList:=columnList || tabColumnsRec.column_name;
			oldColumnList:=oldColumnList || ':old_rec.' || tabColumnsRec.column_name;
			newColumnList:=newColumnList || ':new_rec.' || tabColumnsRec.column_name;
			firstRec:=false;
		end loop;
		close tabColumnsCur;
		--------------------
		begin
			select * into triggerRec from sys.dba_triggers where owner='CUSTOMS' and trigger_name=upper(tableName) || '_MR';
			mrTriggerFound:=true;
			exception
				when NO_DATA_FOUND then
					mrTriggerFound:=false;
		end;
		--if SQL%ROWCOUNT=0 then
		if /*mrTriggerFound*/ false then
			firstRec:=true;
		else
			createStmt:=              'CREATE OR REPLACE TRIGGER journal.' || tableName || '_JN_TRG AFTER INSERT OR DELETE OR UPDATE' || chr(10);
			createStmt:=createStmt || 'ON ' || schemaName || '.' || tableName || ' REFERENCING OLD AS old_rec NEW AS new_rec FOR EACH ROW' || chr(10);
			createStmt:=createStmt || 'declare' || chr(10);
			createStmt:=createStmt || ' opCode						char(3);' || chr(10);
			createStmt:=createStmt || ' suppSrceCd				number(3):=null;' || chr(10);
			createStmt:=createStmt || ' suppTitleCd				number(2):=null;' || chr(10);
			createStmt:=createStmt || ' suppLetrNo				varchar2(50):=null;' || chr(10);
			createStmt:=createStmt || ' suppLetrDt				date:=null;' || chr(10);
			createStmt:=createStmt || ' OldKey				    varchar2(200):=null;' || chr(10);
			createStmt:=createStmt || 'begin' || chr(10);
			createStmt:=createStmt || ' if journal.db_journal.is_journaling_on=false then return; end if;' || chr(10);
			createStmt:=createStmt || ' journal.db_journal.get_journaling_params(suppSrceCd,suppTitleCd,suppLetrNo,suppLetrDt,OldKey);' || chr(10);
			createStmt:=createStmt || ' if suppSrceCd	is null then raise_application_error(-20000,''Cannot insert null into journal.' || tableName || '_JN.SUPP_SRCE_CD'',true); end if;' || chr(10);
			createStmt:=createStmt || ' if suppTitleCd	is null then raise_application_error(-20000,''Cannot insert null into journal.' || tableName || '_JN.SUPP_TITLE_CD'',true); end if;' || chr(10);
			createStmt:=createStmt || ' if suppLetrNo	is null then raise_application_error(-20000,''Cannot insert null into journal.' || tableName || '_JN.SUPP_LETR_NO'',true); end if;' || chr(10);
			createStmt:=createStmt || ' if suppLetrDt	is null then raise_application_error(-20000,''Cannot insert null into journal.' || tableName || '_JN.SUPP_LETR_DT'',true); end if;' || chr(10);
			createStmt:=createStmt || ' if deleting or updating then' || chr(10);
			createStmt:=createStmt || '  if deleting then opCode:=''DEL'';  else opCode:=''UPB''; end if;' || chr(10);
			createStmt:=createStmt || '  insert into journal.' || tableName || '_jn(' || columnList || ',JN_OPERATION,JN_ORACLE_USER,JN_DATETIME,JN_NOTES,JN_APPLN,JN_SESSION,SUPP_SRCE_CD,SUPP_TITLE_CD,SUPP_LETR_NO,SUPP_LETR_DT,JN_OLDKEY) values (' || oldColumnList || ',opCode,user,sysdate,null,null,null,suppSrceCd,suppTitleCd,suppLetrNo,suppLetrDt,oldkey);' || chr(10);
			createStmt:=createStmt || ' end if;' || chr(10);
			createStmt:=createStmt || ' if inserting or updating then' || chr(10);
			createStmt:=createStmt || '  if inserting then opCode:=''INS''; else opCode:=''UPA''; end if;' || chr(10);
			createStmt:=createStmt || '  insert into journal.' || tableName || '_jn(' || columnList || ',JN_OPERATION,JN_ORACLE_USER,JN_DATETIME,JN_NOTES,JN_APPLN,JN_SESSION,SUPP_SRCE_CD,SUPP_TITLE_CD,SUPP_LETR_NO,SUPP_LETR_DT,JN_OLDKEY) values (' || newColumnList || ',opCode,user,sysdate,null,null,null,suppSrceCd,suppTitleCd,suppLetrNo,suppLetrDt,oldkey);' || chr(10);
			createStmt:=createStmt || ' end if;' || chr(10);
			createStmt:=createStmt || ' journal.db_journal.clear_oldkey;' || chr(10);
  		    createStmt:=createStmt || 'end;' || chr(10);
		end if;
		execute immediate createStmt;
	end;
END;

/


CREATE OR REPLACE PUBLIC SYNONYM DB_JOURNAL FOR JOURNAL.DB_JOURNAL;


GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO CUSTOMS;

GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO PP_CUSTOMS;

GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO QA_CUSTOMS;

GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO UAT_CUSTOMS;
