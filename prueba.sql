create or replace procedure PRINCIPAL(p_usuario DBA_USERS.USERNAME%TYPE)
is
	cursor c_tables
	is
	select TABLE_NAME
	from DBA_TABLES
	where OWNER = p_usuario;
	v_tables c_tables%ROWTYPE;
	v_noDataFound exception;
begin
	open c_tables;
	fetch c_tables into v_tables;
	if c_tables%FOUND then
			while c_tables%FOUND loop
				COLUMNS1(p_usuario, v_tables.TABLE_NAME);
				fetch c_tables into v_tables;	
			end loop;
	else
		raise v_noDataFound;
	end if;
	close c_tables;
exception
	when v_noDataFound then
		dbms_output.put_line('No existe ese usuario');
end;
/

create or replace procedure COLUMNS1 (p_usuario DBA_USERS.USERNAME%TYPE,
									 p_tableName DBA_TABLES.TABLE_NAME%TYPE)
is
	cursor c_columns
	is
	select COLUMN_NAME, DATA_TYPE, CHAR_LENGTH
	from DBA_TAB_COLUMNS
	where OWNER = p_usuario
	and TABLE_NAME = p_tableName;
	v_columns c_columns%ROWTYPE;
	v_contcol number:=0;
	v_colvar VARCHAR2(50);
begin
	dbms_output.put_line('CREATE TABLE '||p_tableName||'(');
	for v_columns in c_columns loop
		v_colvar:=(chr(9));
		if v_contcol!=0 then
			v_colvar:=(', '||v_colvar);
		end if;
		PROCOLUMNS (p_tableName, v_columns.COLUMN_NAME, v_columns.DATA_TYPE, v_columns.CHAR_LENGTH,v_colvar);
		v_contcol:=1;
	end loop;
	CONSTRAINTS (p_usuario, p_tableName);
	dbms_output.put_line(');');
	dbms_output.put_line(chr(9));
end;
/

create or replace procedure CONSTRAINTS (p_usuario DBA_USERS.USERNAME%TYPE,
										 p_tableName DBA_TABLES.TABLE_NAME%TYPE)
is
	cursor c_constraint
	is
	select CONSTRAINT_NAME, 
		   CONSTRAINT_TYPE, 
		   SEARCH_CONDITION, 
		   R_CONSTRAINT_NAME
	from DBA_CONSTRAINTS
		where TABLE_NAME=p_tableName
		and OWNER=p_usuario;
	v_constraint c_constraint%ROWTYPE;
begin
	for v_constraint in c_constraint loop
		CONSTCONSTRAINT(p_usuario,
					   p_tableName, 
					   v_constraint.CONSTRAINT_NAME,
					   v_constraint.R_CONSTRAINT_NAME,
					   v_constraint.SEARCH_CONDITION, 
					   v_constraint.CONSTRAINT_TYPE);
	end loop;
end;
/

create or replace procedure CONSTCONSTRAINT (p_usuario DBA_USERS.USERNAME%TYPE,
											 p_tableName DBA_TABLES.TABLE_NAME%TYPE,
											 p_constraint DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE,
											 p_refConstraintName DBA_CONSTRAINTS.R_CONSTRAINT_NAME%TYPE,
											 p_searchCondition DBA_CONSTRAINTS.SEARCH_CONDITION%TYPE,
											 p_contraintType DBA_CONSTRAINTS.CONSTRAINT_TYPE%TYPE)
is
	v_consvar VARCHAR2(200);
begin
    v_consvar:=(chr(9)||', CONSTRAINT ');
    case
        when p_contraintType='P' then
			v_consvar:=(v_consvar||p_constraint||' PRIMARY KEY(');
			CONSTRAINTDEFAULT(p_usuario, p_constraint,v_consvar);
			dbms_output.put_line(v_consvar);
        when p_contraintType='R' then
			v_consvar:=(v_consvar||p_constraint||' FOREIGN KEY(' );
			CONSTRAINTFOREING(p_usuario, p_constraint, p_refConstraintName, v_consvar);
			dbms_output.put_line(v_consvar);
        when p_contraintType='U' then
			v_consvar:=(v_consvar||p_constraint||' UNIQUE(');
			CONSTRAINTDEFAULT(p_usuario, p_constraint,v_consvar);
			dbms_output.put_line(v_consvar);			
        when p_contraintType='C' then
            v_consvar:=(v_consvar||p_constraint||' CHECK(');
			CONSTRAINTCHEK(p_usuario, p_constraint, UPPER(p_searchCondition), v_consvar);
			dbms_output.put_line(v_consvar);
    end case;	
end;
/

create or replace procedure CONSTRAINTCHEK (p_usuario DBA_USERS.USERNAME%TYPE,
											p_constraint DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE,
											p_searchCondition DBA_CONSTRAINTS.SEARCH_CONDITION%TYPE,
											p_consvar in out VARCHAR2)
is
	v_constckeck DBA_CONSTRAINTS.SEARCH_CONDITION%TYPE;
begin
	v_constckeck:=p_searchCondition;
	if v_constckeck like '%REGEXP_LIKE%' then
		v_constckeck:=SINTAXIRREGULAR(v_constckeck);
		p_consvar:=(p_consvar||v_constckeck||')');
	else
		p_consvar:=(p_consvar||v_constckeck||')');
	end if;
end;
/	

create or replace function SINTAXIRREGULAR(p_constckeck DBA_CONSTRAINTS.SEARCH_CONDITION%TYPE)
return VARCHAR2
is
	v_constckeck DBA_CONSTRAINTS.SEARCH_CONDITION%TYPE;
begin
	v_constckeck:=replace(p_constckeck, 'REGEXP_LIKE','');
	v_constckeck:=replace(v_constckeck, '(','');
	v_constckeck:=replace(v_constckeck, ')','');	
	v_constckeck:=replace(v_constckeck, ',', '~');
	return v_constckeck;
end;
/

CONSTRAINTFOREING
			CONSTRAINTUNIQUE;
            CONSTRAINTCHEK;

create or replace procedure CONSTRAINTFOREING(p_usuario DBA_USERS.USERNAME%TYPE,
											  p_constraint DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE,
											  p_refConstraintName DBA_CONSTRAINTS.R_CONSTRAINT_NAME%TYPE,
											  p_consvar in out VARCHAR2)
is
	v_tableR DBA_CONSTRAINTS.TABLE_NAME%TYPE;
	v_consdef VARCHAR2(50);
begin
	v_consdef:=' ';
	select TABLE_NAME into v_tableR
	from DBA_CONSTRAINTS
		where CONSTRAINT_NAME=p_refConstraintName
		and OWNER=p_usuario;
	CONSTRAINTDEFAULT(p_usuario, p_constraint, v_consdef);
	p_consvar:=(p_consvar||v_consdef||' REFERENCES '||v_tableR|| '(');
	v_consdef:=' ';
	CONSTRAINTDEFAULT(p_usuario, p_refConstraintName, v_consdef);
	p_consvar:=(p_consvar||v_consdef);
end;
/



create or replace procedure CONSTRAINTDEFAULT(p_usuario DBA_USERS.USERNAME%TYPE,
											  p_constraint DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE,
											  p_consvar in out VARCHAR2)
is
	cursor c_column
	is
	select COLUMN_NAME
	from DBA_CONS_COLUMNS
		where CONSTRAINT_NAME=p_constraint
		and OWNER=p_usuario;
	v_columns c_column%ROWTYPE;
	v_contcons number:=0;
	v_atrib VARCHAR2(50);
begin
	v_atrib:='';
	for v_columns in c_column loop
		if v_contcons!=0 then
			v_atrib:=(',');
		end if;
		p_consvar:=(p_consvar||v_atrib||v_columns.COLUMN_NAME);
		v_contcons:=1;
	end loop;
	p_consvar:=(p_consvar||')');
end;
/

create or replace procedure PROCOLUMNS (p_tableName DBA_TAB_COLUMNS.TABLE_NAME%TYPE,
                                       p_columnName DBA_TAB_COLUMNS.COLUMN_NAME%TYPE,
                                       p_dataType DBA_TAB_COLUMNS.DATA_TYPE%TYPE,
                                       p_charLength DBA_TAB_COLUMNS.CHAR_LENGTH%TYPE,
									   v_colvar VARCHAR2)
is
begin
	if p_dataType='VARCHAR2' then
			dbms_output.put_line(v_colvar||p_columnName||' VARCHAR ('||p_charLength||')');
	elsif p_dataType='NUMBER' then
			dbms_output.put_line(v_colvar||p_columnName||' NUMERIC');
	else
			dbms_output.put_line(v_colvar||p_columnName||' '||p_dataType);
	end if;
end;
/
		





