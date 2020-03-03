**1. Importad el fichero resultante de la exportación completa de las tablas y los datos de una instancia de ORACLE en otra instancia diferente empleando el comando impdp y explicad qué problemas surgen. Realizad un remapeo de esquemas si es necesario.**


**2. Cread la estructura de tablas de uno de vuestros proyectos de 1º en ORACLE y, mediante una exportación cread un script básico de creación de las tablas con las respectivas restricciones. Realizad de la forma más automatizada posible las acciones necesarias para transformar ese script generado por ORACLE en un script de creación de tablas para Postgres. Documentar todas las acciones realizadas y el código usado para llevarlas a cabo.**


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


**3. SQL*Loader es una herramienta que sirve para cargar grandes volúmenes de datos en una instancia de ORACLE. Exportad los datos de uno de vuestros proyectos de 1º desde Postgres a texto plano con delimitadores y emplead SQL*Loader para realizar el proceso de carga de dichos datos a una instancia ORACLE. Debéis explicar los distintos ficheros de configuración y de log que tiene SQL*Loader.**

Para exportar los datos de Postgres se va a crear un script que utilice el comando de postgres COPY que es el siguiente:
~~~
COPY <tabla> TO <ruta_del_fichero> WITH (DELIMITER E'\t');
~~~

En este caso el delimitador será el tabulador.

El script es el siguiente:
~~~
#! \bin\bash
var='yes'
exportar(){
	if [ $var != 'no' ]
	then
		var='no'
		echo 'Nombre del usuario de postgres con privilegios suficientes: '
		read user
		echo 'Base de datos:'
		read basedatos
		exptabla
	else
		exptabla
	fi
}

exptabla(){
	echo 'Estas son las tablas de la base de datos '$basedatos':'
	psql -h localhost -U $user -d $basedatos -c "\d"
	echo 'Introduzca la tabla que quieres exportar: '
	read tabla
	psql -h localhost -U $user -d $basedatos -c "COPY $tabla TO '/var/lib/postgresql/exp/$tabla.txt' WITH (DELIMITER E'\t');"	
}

salir(){
	while [ $res == "si" -o $res == "s" -o $res == "y" -o $res == "yes" ]
	do
		exportar
		echo '¿Quieres exportar?'
		read res
	done
}

echo '¿Quieres exportar?'
read res
salir
~~~

A continuación, una pequeña muestra del uso del script:
~~~
postgres@servidor:~/exp$ bash exp.sh 
¿Quieres exportar?
si
Nombre del usuario de postgres con privilegios suficientes: 
postgres
Base de datos:
paloma
Estas son las tablas de la base de datos paloma:
Password for user postgres: 
                   List of relations
 Schema |            Name            | Type  |  Owner   
--------+----------------------------+-------+----------
 public | aspectos                   | table | postgres
 public | catadores                  | table | postgres
 public | colaboraciones             | table | postgres
 public | composicion_ing_preparados | table | postgres
 public | experimentos               | table | postgres
 public | ingredientes               | table | postgres
 public | ingredientes_por_version   | table | postgres
 public | investigadores             | table | postgres
 public | puntuaciones               | table | postgres
 public | versiones                  | table | postgres
(10 rows)

Introduzca la tabla que quieres exportar: 
aspectos
Password for user postgres: 
COPY 7
¿Quieres exportar?
si
Estas son las tablas de la base de datos paloma:
Password for user postgres: 
                   List of relations
 Schema |            Name            | Type  |  Owner   
--------+----------------------------+-------+----------
 public | aspectos                   | table | postgres
 public | catadores                  | table | postgres
 public | colaboraciones             | table | postgres
 public | composicion_ing_preparados | table | postgres
 public | experimentos               | table | postgres
 public | ingredientes               | table | postgres
 public | ingredientes_por_version   | table | postgres
 public | investigadores             | table | postgres
 public | puntuaciones               | table | postgres
 public | versiones                  | table | postgres
(10 rows)

Introduzca la tabla que quieres exportar: 
catadores
...
~~~

Con este script se ha creado 10 ficheros con los datos de cada tabla. A continuación, se procede a la carga de datos en Oracle. Para la comprobación se ha creado un usuario, exportacion, que contiene tablas con la misma estructura que las tablas de los datos que se ha exportado en Postgres.

Se crean 10 ficheros con extensión .ctl para Oracle cargue los datos a través de SQL Loader con la siguiente información:
~~~
LOAD DATA
INFILE '/home/oracle/aspectos.txt'
INTO TABLE aspectos
FIELDS TERMINATED BY x'09'
(
    CODIGO,
	DESCRIPCION,
	IMPORTANCIA
)

LOAD DATA
INFILE '/home/oracle/catadores.txt'
INTO TABLE catadores
FIELDS TERMINATED BY x'09'
(
    NIF,
	NOMBRE,
	APELLIDOS,
	DIRECCION,
	TELEFONO
)

LOAD DATA
INFILE '/home/oracle/colaboraciones.txt'
INTO TABLE colaboraciones
FIELDS TERMINATED BY x'09'
(
    COD_EXP,
	COD_VERS,
	NIF_INV
)

LOAD DATA
INFILE '/home/oracle/composicion_ing_preparados.txt'
INTO TABLE composicion_ing_preparados
FIELDS TERMINATED BY x'09'
(
    COD_ING_BASE,
	COD_ING_FINAL,
	CANTIDAD
)

LOAD DATA
INFILE '/home/oracle/experimentos.txt'
INTO TABLE experimentos
FIELDS TERMINATED BY x'09'
(
    CODIGO,
	NIF_INV,
	NOMBRE,
	FECHA_INICIO,
	FECHA_FIN
)

LOAD DATA
INFILE '/home/oracle/ingredientes_por_version.txt'
INTO TABLE ingredientes_por_version
FIELDS TERMINATED BY x'09'
(
    COD_ING,
	COD_EXP,
	COD_VERS,
	CANTIDAD
)

LOAD DATA
INFILE '/home/oracle/ingredientes.txt'
INTO TABLE ingredientes
FIELDS TERMINATED BY x'09'
(
    CODIGO,
	NOMBRE,
	TIPO
)

LOAD DATA
INFILE '/home/oracle/investigadores.txt'
INTO TABLE investigadores
FIELDS TERMINATED BY x'09'
(
    NIF,
	NOMBRE,
	APELLIDOS,
	DIRECCION,
	TELEFONO,
	ESPECIALIDAD
)

LOAD DATA
INFILE '/home/oracle/puntuaciones.txt'
INTO TABLE puntuaciones
FIELDS TERMINATED BY x'09'
(
    NIF_CAT,
	COD_ASP,
	COD_EXP,
	COD_VERS,
	VALOR
)

LOAD DATA
INFILE '/home/oracle/versiones.txt'
INTO TABLE versiones
FIELDS TERMINATED BY x'09'
(
    CODIGO,
	COD_EXP,
	FECHA_PRUEBA
)
~~~

Se crea otro script para la importación de los datos donde se va a usar el siguiente comando:
~~~
sqlldr <usuario>/<contraseña> control=<fichero.ctl> data=<fichero.txt> log='/tmp/bd.log' 
~~~

El script es el siguiente:
~~~
#! \bin\bash
var='yes'
importar(){
	if [ $var != 'no' ]
	then
		var='no'
		echo 'Nombre del usuario de ORACLE: '
		read user
		echo 'Contraseña:'
		read pswd
		imptabla
	else
		imptabla
	fi
}

imptabla(){
	echo 'Introduzca la tabla que quieres importar: '
	read tabla
	sqlldr $user/$pswd control=$tabla'.ctl' data=$tabla'.txt' log='/tmp/bd.log'
}

salir(){
	while [ $res == "si" -o $res == "s" -o $res == "y" -o $res == "yes" ]
	do
		importar
		echo '¿Quieres importar?'
		read res
	done
}

echo '¿Quieres importar?'
read res
salir
~~~

Y esto es un pequeño ejemplo del uso del script:
~~~
oracle@servidororacle:~$ bash cargar.sh 
¿Quieres importar?
si
Nombre del usuario de ORACLE: 
exportacion
Contraseña:
exportacion 
Introduzca la tabla que quieres importar: 
aspectos

SQL*Loader: Release 12.2.0.1.0 - Production on Sáb Feb 29 22:54:51 2020

Copyright (c) 1982, 2017, Oracle and/or its affiliates.  All rights reserved.

Ruta de acceso utilizada:      Convencional
Punto de confirmación alcanzado - recuento de registros lógicos 7

Tabla ASPECTOS:
  7 Filas cargadas correctamente.

Consulte el archivo log:
  /tmp/bd.log
para obtener más información sobre la carga.
¿Quieres importar?
si
Introduzca la tabla que quieres importar: 
catadores

SQL*Loader: Release 12.2.0.1.0 - Production on Sáb Feb 29 23:12:44 2020

Copyright (c) 1982, 2017, Oracle and/or its affiliates.  All rights reserved.

Ruta de acceso utilizada:      Convencional
Punto de confirmación alcanzado - recuento de registros lógicos 5

Tabla CATADORES:
  5 Filas cargadas correctamente.

Consulte el archivo log:
  /tmp/bd.log
para obtener más información sobre la carga.
¿Quieres importar?
si
Introduzca la tabla que quieres importar: 
colaboraciones
...
~~~

Y este es el resultado de una consulta de la base de datos tras cargar todos los datos:
~~~
SQL> select * from aspectos;

COD DESCRIPCION 				       				   IMPORTAN
--- -------------------------------------------------- --------
COL Color					       					   Baja
TEX Textura					       					   Alta
VOL Volumen					       					   Media
CAN Cantidad					   					   Alta
PRE Presentacion				   					   Alta
TEC Tecnica					       					   Media
ORI Originalidad				   					   media

7 filas seleccionadas.
~~~


