#!/bin/bash
# $Id$
#
# =============================================================================
# Move Indexes to a different TS
# -----------------------------------------------------------------------------
#                                                              Itzchak Rehberg
#
#
if [ -z "$3" ]; then
  SCRIPT=${0##*/}
  echo
  echo ============================================================================
  echo "${SCRIPT}       (c) 2003 by Itzchak Rehberg & IzzySoft (devel@izzysoft.de)"
  echo ----------------------------------------------------------------------------
  echo This script is intended to move all indexes for one schema into a different 
  echo TableSpace. First configure your SYS user / passwd inside this script, then
  echo call this script using the following syntax:
  echo ----------------------------------------------------------------------------
  echo "Syntax: ${SCRIPT} <ORACLE_SID> <SourceTS> <TargetTS>"
  echo ============================================================================
  echo
  exit 1
fi

# =================================================[ Configuration Section ]===
# Eval params
export ORACLE_SID=$1
STS=$2
TTS=$3
# login information
user=sys
password="pyha#"
# name of the file to write the log to (or 'OFF' for no log). This file will
# be overwritten without warning!
SPOOL="idxrep__$1-$2-$3.spool"

# ====================================================[ Script starts here ]===
version='0.1.2'
$ORACLE_HOME/bin/sqlplus -s /NOLOG <<EOF

CONNECT $user/$password@$1
Set TERMOUT ON
Set SCAN OFF
Set SERVEROUTPUT On Size 1000000
Set LINESIZE 300
Set TRIMSPOOL On 
Set FEEDBACK OFF
Set Echo Off
SPOOL $SPOOL

DECLARE
  L_LINE VARCHAR(4000);
  TIMESTAMP VARCHAR2(20);

  CURSOR C_INDEX IS
    SELECT index_name,owner
      FROM all_indexes
     WHERE lower(index_type)='normal'
       AND lower(tablespace_name)=lower('$STS');

PROCEDURE moveidx (line IN VARCHAR2) IS
  TIMESTAMP VARCHAR2(20);
BEGIN
  SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') INTO TIMESTAMP FROM DUAL;
  dbms_output.put_line('+ '||TIMESTAMP||line||' ONLINE');
  EXECUTE IMMEDIATE line||' ONLINE';
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      dbms_output.put_line('  '||TIMESTAMP||' '||line);
      EXECUTE IMMEDIATE line;
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('! '||TIMESTAMP||' ALTER INDEX failed!');
    END;
END;

BEGIN
  SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') INTO TIMESTAMP FROM DUAL;
  L_LINE := '* '||TIMESTAMP||' Moving all indices from TS $STS to TS $TTS:';
  dbms_output.put_line(L_LINE);
  FOR Rec_INDEX IN C_INDEX LOOP
    L_LINE := ' ALTER INDEX '||Rec_INDEX.owner||'.'||Rec_INDEX.index_name||
              ' REBUILD TABLESPACE $TTS';
    moveidx(L_LINE);
  END LOOP;
  SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') INTO TIMESTAMP FROM DUAL;
  L_LINE := '* '||TIMESTAMP||'...done.';
  dbms_output.put_line(L_LINE);
END;
/

SPOOL off

EOF
