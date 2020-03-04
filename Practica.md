# Movimiento de datos
### 1. Realiza una exportación del esquema de SCOTT usando la consola Enterprise Manager, con las siguientes condiciones:**

- **Exporta tanto la estructura de las tablas como los datos de las mismas.**

- **Excluye la tabla SALGRADE y los departamentos que no tienen empleados.**

- **Programa la operación para dentro de 15 minutos.**

- **Genera un archivo de log en el directorio raíz de ORACLE.**

**Realiza ahora la operación con Oracle Data Pump.**

Toda la información para la utilizaciónd e Oracle Data Pump se ha extraído de la [documentación oficial de Oracle](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sutil/oracle-data-pump-overview.html).

Para la exportación con Oracle Data Pump se necesita crear un directorio con la siguiente sintaxis:
~~~
CREATE DIRECTORY <nombre_del_directorio> as '<ruta_en_el_sistema>';
~~~

Se va a crear un directorio en **/opt/oracle/product/12.2.0.1/dbhome_1/export** y, demás, se le va a otorgar privilegios de lectura y escritura al usuario **system** que será el encarfado de realizar las exportaciones:
~~~
SQL> CREATE DIRECTORY expdp_dir as '/opt/oracle/product/12.2.0.1/dbhome_1/export';

Directorio creado.

SQL> grant read,write on directory expdp_dir to system;

Concesión terminada correctamente.
~~~

También hay que otorgarle los privilegios al usuario con el que se van a realizar las exportaciones y las importaciones:
~~~
GRANT EXP_FULL_DATABASE to system;
GRANT IMP_FULL_DATABASE to system;
~~~

Con el comando **expdb** se realizan las exportaciones. Para realizar una exportación completa de la base de datos:
~~~
expdp <usuario>/<contraseña> DIRECTORY=<directorio> DUMPFILE=<nombre_fichero>.dmp FULL=Y LOGFILE=<nombre_fichero>.log
~~~

> Para indicar el fichero de log se utiliza **LOGFILE**.

También se pueden realizar exportaciones de un esquema concreto:
~~~
expdp <usuario>/<contraseña> schemas=<esquema> DIRECTORY=<directorio> DUMPFILE=<nombre_fichero>.dmp LOGFILE=<nombre_fichero>.log
~~~

Otras opciones que se pueden utilizar para la exportación desde la línea de comando son:
- **CONTENT={ ALL | DATA_ONLY | METADATA_ONLY}**: para especificar lo que se quiere exportar.
- **INCLUDE=<tipo_objeto>[:clausula]**: incluye más detalladamente.
- **EXCLUDE=<tipo_objeto>[:clausula]**: excluye más detalladamente.
- **QUERY='[esquema.][tabla:] "clausula"'**: filtra los datos de las tablas.

> Exportación del esquema SCOTT:
~~~
oracle@servidororacle:~$ expdp SYSTEM SCHEMAS=SCOTT DUMPFILE=SCOTT.dmp DIRECTORY=dp VERSION=12.0 LOGFILE=SCOTT.log

Export: Release 12.2.0.1.0 - Production on Jue Feb 20 12:12:24 2020

Copyright (c) 1982, 2017, Oracle and/or its affiliates.  All rights reserved.
Contraseña: 

Conectado a: Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

Advertencia: Las operaciones de Oracle Data Pump no se necesitan normalmente cuando se conecta a la raíz o al elemento inicial de una base de datos del contenedor.


Advertencia: Oracle Data Pump está exportando desde una base de datos que soporta identificadores largos a una versión que no soporta identificadores largos.

Iniciando "SYSTEM"."SYS_EXPORT_SCHEMA_01":  SYSTEM/******** SCHEMAS=SCOTT DUMPFILE=SCOTT.dmp DIRECTORY=dp VERSION=12.0 LOGFILE=SCOTT.log 
Procesando el tipo de objeto SCHEMA_EXPORT/DEFAULT_ROLE
Procesando el tipo de objeto SCHEMA_EXPORT/PRE_SCHEMA/PROCACT_SCHEMA
La tabla maestra "SYSTEM"."SYS_EXPORT_SCHEMA_01" se ha cargado/descargado correctamente
******************************************************************************
El juego de archivos de volcado para SYSTEM.SYS_EXPORT_SCHEMA_01 es:
  /opt/oracle/datafile/SCOTT.dmp
El trabajo "SYSTEM"."SYS_EXPORT_SCHEMA_01" ha terminado correctamente en Jue Feb 20 12:13:13 2020 elapsed 0 00:00:44
~~~

Las exportaciones pueden programarse creando un fichero con extensión .par donde se indique las opciones de la exportación. Por ejemplo:
~~~
userid=system/Oracle19
dumpfile=FULL_DB.dmp
logfile=FULL_DB.log
directory=expdp_dir
full=y
~~~

Se crea un procedimiento donde se indican las credenciales del usuario del sistema que realizará la exportación:
~~~
BEGIN
dbms_credential.create_credential (
  CREDENTIAL_NAME => 'ORACLEOSUSER',
  USERNAME => 'oracle',
  PASSWORD => 'oracle',
  DATABASE_ROLE => NULL,
  WINDOWS_DOMAIN => NULL,
  COMMENTS => 'Oracle OS User',
  ENABLED => true
);
END;
~~~

Y se programa la tarea:
~~~
Begin 
Dbms_scheduler.create_job ( 
  job_name => 'BACKUP_FULLDB', 
  job_type => 'EXTERNAL_SCRIPT', 
  job_action => '/opt/oracle/product/12.2.0.1/dbhome_1/export   parfile=/home/oracle/expdp_tab.par', 
  start_date => sysdate, 
  Repeat_interval =>'BYHOUR=15; BYMINUTE=15',
  enabled => TRUE,
  credential_name=>'ORACLEOSUSER'
); 
end; 
/ 
~~~

### 2. Importa el fichero obtenido anteriormente usando Enterprise Manager pero en un usuario distinto de otra base de datos.
Para las importaciones también hay que crear un directorio, que debe ubicarse en la misma ruta que el derectorio creado para las exportaciones. 
~~~
SQL> CREATE DIRECTORY impdp_dir as '/opt/oracle/product/12.2.0.1/dbhome_1/export';

Directorio creado.

SQL> grant read,write on directory impdp_dir to system;

Concesión terminada correctamente.
~~~

Para importar se utiliza el comando **impdp** de la siguiente forma:
~~~
impdp <usuario>/<contraseña> schemas=<esquema> DIRECTORY=<directorio> DUMPFILE=<nombre_fichero>.dmp LOGFILE=<nombre_fichero>.log
~~~

Además de las opciones que se pueden usar en expdp, también se puede usar las siguientes opciones:
- **REMAP_DATA=[esquema.]tabla.columna:[esquema]paquete.función**: permite el mapeo de datos durante la importación a través de un paquete y una función.
- **REMAP_TABLE**: para renombrar tablas.
- **REMAP_TABLESPACE**: permite especificar el tablespace destino.
- **REPLACE**
- **TRUNCATE**



### 3. Realiza una exportación de la estructura y los datos de todas las tablas de la base de datos usando el comando expdp de Oracle Data Pump encriptando la información. Prueba todas las posibles opciones que ofrece dicho comando y documentándolas adecuadamente.

Para realizar una exportación de la estructura y los datos de todas las tablas:
~~~
oracle@servidororacle:~$ expdp system/Oracle19 full=Y directory=expdp_dir dumpfile=CopiaCompleta.dmp logfile=CopiaCompleta.log

Export: Release 12.2.0.1.0 - Production on Mar Mar 3 21:10:27 2020

Copyright (c) 1982, 2017, Oracle and/or its affiliates.  All rights reserved.

Conectado a: Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

Advertencia: Las operaciones de Oracle Data Pump no se necesitan normalmente cuando se conecta a la raíz o al elemento inicial de una base de datos del contenedor.

Iniciando "SYSTEM"."SYS_EXPORT_FULL_01":  system/******** full=Y directory=expdp_dir dumpfile=CopiaCompleta.dmp logfile=CopiaCompleta.log 
Procesando el tipo de objeto DATABASE_EXPORT/EARLY_OPTIONS/VIEWS_AS_TABLES/TABLE_DATA
Procesando el tipo de objeto DATABASE_EXPORT/NORMAL_OPTIONS/TABLE_DATA
Procesando el tipo de objeto DATABASE_EXPORT/NORMAL_OPTIONS/VIEWS_AS_TABLES/TABLE_DATA
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/TABLE_DATA
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/INDEX/STATISTICS/INDEX_STATISTICS
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/STATISTICS/TABLE_STATISTICS
Procesando el tipo de objeto DATABASE_EXPORT/STATISTICS/MARKER
Procesando el tipo de objeto DATABASE_EXPORT/PRE_SYSTEM_IMPCALLOUT/MARKER
Procesando el tipo de objeto DATABASE_EXPORT/PRE_INSTANCE_IMPCALLOUT/MARKER
Procesando el tipo de objeto DATABASE_EXPORT/TABLESPACE
Procesando el tipo de objeto DATABASE_EXPORT/PROFILE
Procesando el tipo de objeto DATABASE_EXPORT/SYS_USER/USER
Procesando el tipo de objeto DATABASE_EXPORT/RADM_FPTM
Procesando el tipo de objeto DATABASE_EXPORT/GRANT/SYSTEM_GRANT/PROC_SYSTEM_GRANT
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/GRANT/SYSTEM_GRANT
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/ROLE_GRANT
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/DEFAULT_ROLE
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/ON_USER_GRANT
Procesando el tipo de objeto DATABASE_EXPORT/RESOURCE_COST
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/DB_LINK
Procesando el tipo de objeto DATABASE_EXPORT/TRUSTED_DB_LINK
Procesando el tipo de objeto DATABASE_EXPORT/DIRECTORY/DIRECTORY
Procesando el tipo de objeto DATABASE_EXPORT/DIRECTORY/GRANT/OWNER_GRANT/OBJECT_GRANT
Procesando el tipo de objeto DATABASE_EXPORT/SYSTEM_PROCOBJACT/PRE_SYSTEM_ACTIONS/PROCACT_SYSTEM
Procesando el tipo de objeto DATABASE_EXPORT/SYSTEM_PROCOBJACT/PROCOBJ
Procesando el tipo de objeto DATABASE_EXPORT/SYSTEM_PROCOBJACT/POST_SYSTEM_ACTIONS/PROCACT_SYSTEM
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/PROCACT_SCHEMA
Procesando el tipo de objeto DATABASE_EXPORT/EARLY_OPTIONS/VIEWS_AS_TABLES/TABLE
Procesando el tipo de objeto DATABASE_EXPORT/EARLY_POST_INSTANCE_IMPCALLOUT/MARKER
Procesando el tipo de objeto DATABASE_EXPORT/NORMAL_OPTIONS/TABLE
Procesando el tipo de objeto DATABASE_EXPORT/NORMAL_OPTIONS/VIEWS_AS_TABLES/TABLE
Procesando el tipo de objeto DATABASE_EXPORT/NORMAL_POST_INSTANCE_IMPCALLOUT/MARKER
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/TABLE
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/COMMENT
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/INDEX/INDEX
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/TABLE/CONSTRAINT/CONSTRAINT
Procesando el tipo de objeto DATABASE_EXPORT/FINAL_POST_INSTANCE_IMPCALLOUT/MARKER
Procesando el tipo de objeto DATABASE_EXPORT/SCHEMA/POST_SCHEMA/PROCACT_SCHEMA
Procesando el tipo de objeto DATABASE_EXPORT/AUDIT_UNIFIED/AUDIT_POLICY_ENABLE
Procesando el tipo de objeto DATABASE_EXPORT/AUDIT
Procesando el tipo de objeto DATABASE_EXPORT/POST_SYSTEM_IMPCALLOUT/MARKER
. . "SYS"."KU$_USER_MAPPING_VIEW"               6.382 KB      57 filas exportadas
. . "SYS"."AUD$"                                1.274 MB    8696 filas exportadas
. . "SYSTEM"."REDO_DB"                          25.59 KB       1 filas exportadas
. . "ORDDATA"."ORDDCM_DOCS"                     252.9 KB       9 filas exportadas
. . "WMSYS"."WM$WORKSPACES_TABLE$"              12.10 KB       1 filas exportadas
. . "WMSYS"."WM$HINT_TABLE$"                    9.984 KB      97 filas exportadas
. . "LBACSYS"."OLS$INSTALLATIONS"               6.960 KB       2 filas exportadas
. . "WMSYS"."WM$WORKSPACE_PRIV_TABLE$"          7.078 KB      11 filas exportadas
. . "SYS"."DAM_CONFIG_PARAM$"                   6.531 KB      14 filas exportadas
. . "SYS"."TSDP_SUBPOL$"                        6.328 KB       1 filas exportadas
. . "WMSYS"."WM$NEXTVER_TABLE$"                 6.375 KB       1 filas exportadas
. . "LBACSYS"."OLS$PROPS"                       6.234 KB       5 filas exportadas
. . "WMSYS"."WM$ENV_VARS$"                      6.015 KB       3 filas exportadas
. . "SYS"."TSDP_PARAMETER$"                     5.953 KB       1 filas exportadas
. . "SYS"."TSDP_POLICY$"                        5.921 KB       1 filas exportadas
. . "WMSYS"."WM$VERSION_HIERARCHY_TABLE$"       5.984 KB       1 filas exportadas
. . "WMSYS"."WM$EVENTS_INFO$"                   5.812 KB      12 filas exportadas
. . "LBACSYS"."OLS$AUDIT_ACTIONS"               5.757 KB       8 filas exportadas
. . "LBACSYS"."OLS$DIP_EVENTS"                  5.539 KB       2 filas exportadas
. . "LBACSYS"."OLS$AUDIT"                           0 KB       0 filas exportadas
. . "LBACSYS"."OLS$COMPARTMENTS"                    0 KB       0 filas exportadas
. . "LBACSYS"."OLS$DIP_DEBUG"                       0 KB       0 filas exportadas
. . "LBACSYS"."OLS$GROUPS"                          0 KB       0 filas exportadas
. . "LBACSYS"."OLS$LAB"                             0 KB       0 filas exportadas
. . "LBACSYS"."OLS$LEVELS"                          0 KB       0 filas exportadas
. . "LBACSYS"."OLS$POL"                             0 KB       0 filas exportadas
. . "LBACSYS"."OLS$POLICY_ADMIN"                    0 KB       0 filas exportadas
. . "LBACSYS"."OLS$POLS"                            0 KB       0 filas exportadas
. . "LBACSYS"."OLS$POLT"                            0 KB       0 filas exportadas
. . "LBACSYS"."OLS$PROFILE"                         0 KB       0 filas exportadas
. . "LBACSYS"."OLS$PROFILES"                        0 KB       0 filas exportadas
. . "LBACSYS"."OLS$PROG"                            0 KB       0 filas exportadas
. . "LBACSYS"."OLS$SESSINFO"                        0 KB       0 filas exportadas
. . "LBACSYS"."OLS$USER"                            0 KB       0 filas exportadas
. . "LBACSYS"."OLS$USER_COMPARTMENTS"               0 KB       0 filas exportadas
. . "LBACSYS"."OLS$USER_GROUPS"                     0 KB       0 filas exportadas
. . "LBACSYS"."OLS$USER_LEVELS"                     0 KB       0 filas exportadas
. . "SYS"."DAM_CLEANUP_EVENTS$"                     0 KB       0 filas exportadas
. . "SYS"."DAM_CLEANUP_JOBS$"                       0 KB       0 filas exportadas
. . "SYS"."TSDP_ASSOCIATION$"                       0 KB       0 filas exportadas
. . "SYS"."TSDP_CONDITION$"                         0 KB       0 filas exportadas
. . "SYS"."TSDP_FEATURE_POLICY$"                    0 KB       0 filas exportadas
. . "SYS"."TSDP_PROTECTION$"                        0 KB       0 filas exportadas
. . "SYS"."TSDP_SENSITIVE_DATA$"                    0 KB       0 filas exportadas
. . "SYS"."TSDP_SENSITIVE_TYPE$"                    0 KB       0 filas exportadas
. . "SYS"."TSDP_SOURCE$"                            0 KB       0 filas exportadas
. . "SYSTEM"."REDO_LOG"                             0 KB       0 filas exportadas
. . "WMSYS"."WM$BATCH_COMPRESSIBLE_TABLES$"         0 KB       0 filas exportadas
. . "WMSYS"."WM$CONS_COLUMNS$"                      0 KB       0 filas exportadas
. . "WMSYS"."WM$CONSTRAINTS_TABLE$"                 0 KB       0 filas exportadas
. . "WMSYS"."WM$LOCKROWS_INFO$"                     0 KB       0 filas exportadas
. . "WMSYS"."WM$MODIFIED_TABLES$"                   0 KB       0 filas exportadas
. . "WMSYS"."WM$MP_GRAPH_WORKSPACES_TABLE$"         0 KB       0 filas exportadas
. . "WMSYS"."WM$MP_PARENT_WORKSPACES_TABLE$"        0 KB       0 filas exportadas
. . "WMSYS"."WM$NESTED_COLUMNS_TABLE$"              0 KB       0 filas exportadas
. . "WMSYS"."WM$RESOLVE_WORKSPACES_TABLE$"          0 KB       0 filas exportadas
. . "WMSYS"."WM$RIC_LOCKING_TABLE$"                 0 KB       0 filas exportadas
. . "WMSYS"."WM$RIC_TABLE$"                         0 KB       0 filas exportadas
. . "WMSYS"."WM$RIC_TRIGGERS_TABLE$"                0 KB       0 filas exportadas
. . "WMSYS"."WM$UDTRIG_DISPATCH_PROCS$"             0 KB       0 filas exportadas
. . "WMSYS"."WM$UDTRIG_INFO$"                       0 KB       0 filas exportadas
. . "WMSYS"."WM$VERSION_TABLE$"                     0 KB       0 filas exportadas
. . "WMSYS"."WM$VT_ERRORS_TABLE$"                   0 KB       0 filas exportadas
. . "WMSYS"."WM$WORKSPACE_SAVEPOINTS_TABLE$"        0 KB       0 filas exportadas
. . "MDSYS"."RDF_PARAM$"                        6.515 KB       3 filas exportadas
. . "SYS"."AUDTAB$TBS$FOR_EXPORT"               5.953 KB       2 filas exportadas
. . "SYS"."DBA_SENSITIVE_DATA"                      0 KB       0 filas exportadas
. . "SYS"."DBA_TSDP_POLICY_PROTECTION"              0 KB       0 filas exportadas
. . "SYS"."FGA_LOG$FOR_EXPORT"                  20.20 KB       8 filas exportadas
. . "SYS"."NACL$_ACE_EXP"                           0 KB       0 filas exportadas
. . "SYS"."NACL$_HOST_EXP"                      6.976 KB       2 filas exportadas
. . "SYS"."NACL$_WALLET_EXP"                        0 KB       0 filas exportadas
. . "SYS"."SQL$_DATAPUMP"                           0 KB       0 filas exportadas
. . "SYS"."SQLOBJ$AUXDATA_DATAPUMP"                 0 KB       0 filas exportadas
. . "SYS"."SQLOBJ$DATA_DATAPUMP"                    0 KB       0 filas exportadas
. . "SYS"."SQLOBJ$_DATAPUMP"                        0 KB       0 filas exportadas
. . "SYS"."SQLOBJ$PLAN_DATAPUMP"                    0 KB       0 filas exportadas
. . "SYS"."SQL$TEXT_DATAPUMP"                       0 KB       0 filas exportadas
. . "SYSTEM"."SCHEDULER_JOB_ARGS"                   0 KB       0 filas exportadas
. . "SYSTEM"."SCHEDULER_PROGRAM_ARGS"           9.515 KB      12 filas exportadas
. . "WMSYS"."WM$EXP_MAP"                        7.718 KB       3 filas exportadas
. . "WMSYS"."WM$METADATA_MAP"                       0 KB       0 filas exportadas
. . "LUIS"."HOLA"                                   0 KB       0 filas exportadas
La tabla maestra "SYSTEM"."SYS_EXPORT_FULL_01" se ha cargado/descargado correctamente
******************************************************************************
El juego de archivos de volcado para SYSTEM.SYS_EXPORT_FULL_01 es:
  /opt/oracle/product/12.2.0.1/dbhome_1/export/CopiaCompleta.dmp
El trabajo "SYSTEM"."SYS_EXPORT_FULL_01" ha terminado correctamente en Mar Mar 3 21:19:01 2020 elapsed 0 00:08:31
~~~



### 4. Intenta realizar operaciones similares de importación y exportación con las herramientas proporcionadas con Postgres desde línea de comandos, documentando el proceso.

En PostgreSQL hay tres formas de exportar e importar una base de datos o parte de ella que son:
- A través de un fichero con extensión .dump o .sql.
- A través de phpPgAdmin.


#### Exportación a través de ficheros
Como se ha dicho anteriormente las exportaciones o importaciones se pueden realizar a través de fichero .dump o .sql. 

La sintaxis es la siguiente:
~~~
pg_dump -Fc -t <nombre_tabla> <nombre_BDD> -f /<ruta_fichero>.dump
~~~

En nuestro ejemplo se va a exportar la tabla aspectos de la base de datos paloma:
~~~
postgres@servidor:/home/vagrant$ pg_dump -Fc -t aspectos paloma -f /home/postgres/aspectos.dump
~~~

Para exportar con ficheros .sql la sintaxis es casi la misma:
~~~
pg_dump <nombre_BDD> -t <nombre_tabla> > /<ruta_fichero>.sql
~~~

El ejemplo, con la misma tabla y base de datos que anteriomente, es:
~~~
postgres@servidor:/home/postgres$ pg_dump paloma -t aspectos > /home/postgres/aspectos.sql
~~~

La diferencia entre estos ficheros es que en .sql el texto es plano:
~~~
postgres@servidor:/home/postgres$ cat aspectos.sql 
--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7 (Debian 11.7-0+deb10u1)
-- Dumped by pg_dump version 11.7 (Debian 11.7-0+deb10u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: aspectos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aspectos (
    codigo character varying(3) NOT NULL,
    descripcion character varying(50),
    importancia character varying(8),
    CONSTRAINT importancia_format CHECK ((upper((importancia)::text) = ANY (ARRAY['MUY ALTA'::text, 'ALTA'::text, 'MEDIA'::text, 'BAJA'::text]))),
    CONSTRAINT nulo_descrcipcion_asp CHECK ((descripcion IS NOT NULL))
);


ALTER TABLE public.aspectos OWNER TO postgres;

--
-- Data for Name: aspectos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.aspectos (codigo, descripcion, importancia) FROM stdin;
COL	Color	Baja
TEX	Textura	Alta
VOL	Volumen	Media
CAN	Cantidad	Alta
PRE	Presentacion	Alta
TEC	Tecnica	Media
ORI	Originalidad	media
\.


--
-- Name: aspectos pri_aspectos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aspectos
    ADD CONSTRAINT pri_aspectos PRIMARY KEY (codigo);


--
-- PostgreSQL database dump complete
--

~~~

~~~
postgres@servidor:/home/postgres$ cat aspectos.dump 
PGDMP
�xpaloma11.7 (Debian 11.7-0+deb10u1)11.7 (Debian 11.7-0+deb10u1�
                                                                0ENCODINENCODINGSET client_encoding = 'UTF8';
false�
      00
STDSTRINGS
STDSTRINGS(SET standard_conforming_strings = 'on';
false�
      00
SEARCHPATH
SEARCHPATH8SELECT pg_catalog.set_config('search_path', '', false);
false�
      126216385palomDATABASExCREATE DATABASE paloma WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
DROP DATABASE paloma;
postgresfalse�
              00DATABASE palomaACL,GRANT CONNECT ON DATABASE paloma TO paloma;
postgresfalse2976�12595772aspectosTABLEsCREATE TABLE public.aspectos (
    codigo character varying(3) NOT NULL,
    descripcion character varying(50),
    importancia character varying(8),
    CONSTRAINT importancia_format CHECK ((upper((importancia)::text) = ANY (ARRAY['MUY ALTA'::text, 'ALTA'::text, 'MEDIA'::text, 'BAJA'::text]))),
    CONSTRAINT nulo_descrcipcion_asp CHECK ((descripcion IS NOT NULL))
);
DROP TABLE public.aspectos;
publipostgresfalse�
                   05772aspectos
TABLE DATADCOPY public.aspectos (codigo, descripcion, importancia) FROM stdin;
publipostgresfalse20 
                     260657734aspectos pri_aspectos
CONSTRAINTWALTER TABLE ONLY public.aspectos
    ADD CONSTRAINT pri_aspectos PRIMARY KEY (codigo);
?ALTER TABLE ONLY public.aspectos DROP CONSTRAINT pri_aspectos;
publipostgresfalse206�
                      ux�-�A
�0E�3��5d!�)%n>� #�b
wr���،����G�#i��Fﶫd��/�t�������ˎ�'f���*�
~~~

Para exportar la sintaxis es:
~~~
psql -U <usuario> -W -h <hostname> <nombre_BDD> < <fichero_origen>.sql
~~~

A continuación, un ejemplo de la importación de la table aspectos, antes exportada, en una base de datos de prueba:
~~~
postgres@servidor:/home/postgres$ psql -U postgres -W -h localhost pruebaora < aspectos.sql 
Password: 
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 row)

SET
SET
SET
SET
SET
SET
CREATE TABLE
ALTER TABLE
COPY 7
ALTER TABLE
~~~

> Comprobación:
~~~
pruebaora=# \d
          List of relations
 Schema |   Name   | Type  |  Owner   
--------+----------+-------+----------
 public | aspectos | table | postgres
(1 row)
~~~


#### Importación con phpPgAdmin
Tras insertar el usuario y la contraseña, en nuestro caso del usuario Postgres, se selecciona la base de datos, pruebaora. En la máquina donde está abierta la interfaz web hay un fichero .sql con la tabla versiones. Se clicka sobre el botón Examinar... y se selecciona dicho fichero:
[postgres](images/bimg.png)

Al pulsar Ejecutar el resultado es el mismo que si se realiza desde la línea de comandos del sistema origen. En este caso, indica los errores al isnertar los datos, puesto que se ha exportado una clausula de clave foránea de una tabla que en esta base de datos no existe. 
[postgres](images/aimg.png)

Y ahora en la base de datos pruebaora aparece la nueva tabla creada:
[postgres](images/cimg.png)


### 5. Exporta los documentos de una colección de MongoDB que cumplan una determinada condición e impórtalos en otra base de datos.
