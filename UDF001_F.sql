-- ============================================================
-- Source   : UDF001_F
-- Type     : SQL script
-- Purpose  : Creates (or replaces) the overloaded SQL UDF getDate.
--            The function converts a date value to CHAR(10)
--            in the requested output format, by delegating to
--            the service program UDF001.
--
-- Overloads:
--   getDate(INPUT_DATE DATE, OUTPUT_FORMAT CHAR(10))
--       Input is already a DATE; no input format needed.
--       Caller supplies the output format token.
--
--   getDate(INPUT_DATE   NUMERIC(8,0),
--           INPUT_FORMAT  CHAR(10),
--           OUTPUT_FORMAT CHAR(10))
--       Input is a numeric date (e.g. 20260914).
--       Caller supplies both input and output format tokens.
--
-- Supported format tokens:
--   Input  : *YMD *YYMD *MDY *MDYY *DMY *DMYY
--   Output : *YMD *YYMD *MDY *MDYY *DMY *DMYY *ISO
--
-- Usage examples:
--   VALUES getDate(DATE('2026-09-14'), '*DMY')
--   --> '140926    '
--
--   VALUES getDate(DATE('2026-09-14'), '*ISO')
--   --> '2026-09-14'
--
--   VALUES getDate(20260914, '*YYMD', '*DMYY')
--   --> '14092026  '
--
--   VALUES getDate(20260914, '*YYMD', '*ISO')
--   --> '2026-09-14'
--
-- On error (invalid format or API failure), returns '*ERR'.
--
-- Deploy with:
--   RUNSQLSTM SRCFILE(MYLIB/QSQLSRC) SRCMBR(UDF001_F)
--             DFTRDBCOL(MYLIB) COMMIT(*NONE) MARGINS(100)
-- ============================================================

-- ------------------------------------------------------------
-- Overload 1: DATE input
-- Bound to procedure GETDATED in service program UDF001.
-- ------------------------------------------------------------
DROP SPECIFIC FUNCTION IF EXISTS getDateD
;

CREATE OR REPLACE FUNCTION getDate (
    INPUT_DATE    DATE,
    OUTPUT_FORMAT CHAR(10)
)
RETURNS CHAR(10)
SPECIFIC getDateD
LANGUAGE RPGLE
PARAMETER STYLE GENERAL
PROGRAM TYPE SUB
DETERMINISTIC
NO SQL
RETURNS NULL ON NULL INPUT
ALLOW PARALLEL
EXTERNAL NAME 'UDF001(GETDATED)'
;

-- ------------------------------------------------------------
-- Overload 2: NUMERIC(8,0) input
-- Bound to procedure GETDATEN in service program UDF001.
-- ------------------------------------------------------------
DROP SPECIFIC FUNCTION IF EXISTS getDateN
;

CREATE OR REPLACE FUNCTION getDate (
    INPUT_DATE    NUMERIC(8, 0),
    INPUT_FORMAT  CHAR(10),
    OUTPUT_FORMAT CHAR(10)
)
RETURNS CHAR(10)
SPECIFIC getDateN
LANGUAGE RPGLE
PARAMETER STYLE GENERAL
PROGRAM TYPE SUB
DETERMINISTIC
NO SQL
RETURNS NULL ON NULL INPUT
ALLOW PARALLEL
EXTERNAL NAME 'UDF001(GETDATEN)'
;
