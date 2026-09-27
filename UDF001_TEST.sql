-- ============================================================
-- Source   : UDF001_TEST
-- Type     : SQL script — full test suite for getDate (UDF001)
-- Test date: September 14, 2026
--
-- Expected results:
--   *YMD   -> '260914    '
--   *YYMD  -> '20260914  '
--   *MDY   -> '091426    '
--   *MDYY  -> '09142026  '
--   *DMY   -> '140926    '
--   *DMYY  -> '14092026  '
--   *ISO   -> '2026-09-14'
--   errors -> '*ERR      '
--
-- To display only failing rows, add: WHERE CHECK = '*** KO ***'
--
-- Run with:
--   RUNSQLSTM SRCFILE(MYLIB/QSQLSRC) SRCMBR(UDF001_TEST)
--             DFTRDBCOL(MYLIB) COMMIT(*NONE) MARGINS(132)
-- ============================================================

SET PATH = MDUCA1, QSYS, QSYS2, SYSPROC
;

-- ============================================================
-- TEST 1: DATE overload
-- Input: DATE('2026-09-14')
-- All 7 output formats + 2 error cases
-- ============================================================
WITH A AS (
SELECT
    CASE WHEN RESULT = EXPECTED THEN 'OK' ELSE '*** KO ***' END AS CHECK,
    DESCR      AS DESCRIPTION,
    INPUT_DATE AS INPUT_DATE,
    RESULT     AS RESULT,
    EXPECTED   AS EXPECTED
FROM (VALUES
    ('*YMD  OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*YMD' ), '260914    '),
    ('*YYMD OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*YYMD'), '20260914  '),
    ('*MDY  OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*MDY' ), '091426    '),
    ('*MDYY OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*MDYY'), '09142026  '),
    ('*DMY  OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*DMY' ), '140926    '),
    ('*DMYY OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*DMYY'), '14092026  '),
    ('*ISO  OK' , DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*ISO' ), '2026-09-14'),
    -- Invalid output format
    ('*XXX  ERR', DATE('2026-09-14'), getDate(DATE('2026-09-14'), '*XXX' ), '*ERR      '),
    -- Empty output format
    ('empty ERR', DATE('2026-09-14'), getDate(DATE('2026-09-14'), ''     ), '*ERR      ')
) AS T(DESCR, INPUT_DATE, RESULT, EXPECTED)
)
SELECT * FROM A
ORDER BY DESCRIPTION
;

-- ============================================================
-- TEST 2: NUMERIC overload
-- Part A: 42 valid combinations (6 input formats x 7 output formats)
-- Part B: error cases (invalid formats, invalid dates)
-- ============================================================
WITH A AS (
SELECT
    CASE WHEN RESULT = EXPECTED THEN 'OK' ELSE '*** KO ***' END AS CHECK,
    IN_FMT            AS INPUT_FORMAT,
    OUT_FMT           AS OUTPUT_FORMAT,
    CHAR(INPUT_NUM) AS INPUT_VALUE,
    RESULT            AS RESULT,
    EXPECTED          AS EXPECTED
FROM (VALUES
    -- *YMD (260914) -> all output formats
    ('*YMD' ,'*YMD' , 260914, getDate(260914, '*YMD' , '*YMD' ), '260914    '),
    ('*YMD' ,'*YYMD', 260914, getDate(260914, '*YMD' , '*YYMD'), '20260914  '),
    ('*YMD' ,'*MDY' , 260914, getDate(260914, '*YMD' , '*MDY' ), '091426    '),
    ('*YMD' ,'*MDYY', 260914, getDate(260914, '*YMD' , '*MDYY'), '09142026  '),
    ('*YMD' ,'*DMY' , 260914, getDate(260914, '*YMD' , '*DMY' ), '140926    '),
    ('*YMD' ,'*DMYY', 260914, getDate(260914, '*YMD' , '*DMYY'), '14092026  '),
    ('*YMD' ,'*ISO' , 260914, getDate(260914, '*YMD' , '*ISO' ), '2026-09-14'),
    -- *YYMD (20260914) -> all output formats
    ('*YYMD','*YMD' , 20260914, getDate(20260914, '*YYMD', '*YMD' ), '260914    '),
    ('*YYMD','*YYMD', 20260914, getDate(20260914, '*YYMD', '*YYMD'), '20260914  '),
    ('*YYMD','*MDY' , 20260914, getDate(20260914, '*YYMD', '*MDY' ), '091426    '),
    ('*YYMD','*MDYY', 20260914, getDate(20260914, '*YYMD', '*MDYY'), '09142026  '),
    ('*YYMD','*DMY' , 20260914, getDate(20260914, '*YYMD', '*DMY' ), '140926    '),
    ('*YYMD','*DMYY', 20260914, getDate(20260914, '*YYMD', '*DMYY'), '14092026  '),
    ('*YYMD','*ISO' , 20260914, getDate(20260914, '*YYMD', '*ISO' ), '2026-09-14'),
    -- *MDY (091426) -> all output formats
    ('*MDY' ,'*YMD' , 91426, getDate(91426, '*MDY' , '*YMD' ), '260914    '),
    ('*MDY' ,'*YYMD', 91426, getDate(91426, '*MDY' , '*YYMD'), '20260914  '),
    ('*MDY' ,'*MDY' , 91426, getDate(91426, '*MDY' , '*MDY' ), '091426    '),
    ('*MDY' ,'*MDYY', 91426, getDate(91426, '*MDY' , '*MDYY'), '09142026  '),
    ('*MDY' ,'*DMY' , 91426, getDate(91426, '*MDY' , '*DMY' ), '140926    '),
    ('*MDY' ,'*DMYY', 91426, getDate(91426, '*MDY' , '*DMYY'), '14092026  '),
    ('*MDY' ,'*ISO' , 91426, getDate(91426, '*MDY' , '*ISO' ), '2026-09-14'),
    -- *MDYY (09142026) -> all output formats
    ('*MDYY','*YMD' , 9142026, getDate(9142026, '*MDYY', '*YMD' ), '260914    '),
    ('*MDYY','*YYMD', 9142026, getDate(9142026, '*MDYY', '*YYMD'), '20260914  '),
    ('*MDYY','*MDY' , 9142026, getDate(9142026, '*MDYY', '*MDY' ), '091426    '),
    ('*MDYY','*MDYY', 9142026, getDate(9142026, '*MDYY', '*MDYY'), '09142026  '),
    ('*MDYY','*DMY' , 9142026, getDate(9142026, '*MDYY', '*DMY' ), '140926    '),
    ('*MDYY','*DMYY', 9142026, getDate(9142026, '*MDYY', '*DMYY'), '14092026  '),
    ('*MDYY','*ISO' , 9142026, getDate(9142026, '*MDYY', '*ISO' ), '2026-09-14'),
    -- *DMY (140926) -> all output formats
    ('*DMY' ,'*YMD' , 140926, getDate(140926, '*DMY' , '*YMD' ), '260914    '),
    ('*DMY' ,'*YYMD', 140926, getDate(140926, '*DMY' , '*YYMD'), '20260914  '),
    ('*DMY' ,'*MDY' , 140926, getDate(140926, '*DMY' , '*MDY' ), '091426    '),
    ('*DMY' ,'*MDYY', 140926, getDate(140926, '*DMY' , '*MDYY'), '09142026  '),
    ('*DMY' ,'*DMY' , 140926, getDate(140926, '*DMY' , '*DMY' ), '140926    '),
    ('*DMY' ,'*DMYY', 140926, getDate(140926, '*DMY' , '*DMYY'), '14092026  '),
    ('*DMY' ,'*ISO' , 140926, getDate(140926, '*DMY' , '*ISO' ), '2026-09-14'),
    -- *DMYY (14092026) -> all output formats
    ('*DMYY','*YMD' , 14092026, getDate(14092026, '*DMYY', '*YMD' ), '260914    '),
    ('*DMYY','*YYMD', 14092026, getDate(14092026, '*DMYY', '*YYMD'), '20260914  '),
    ('*DMYY','*MDY' , 14092026, getDate(14092026, '*DMYY', '*MDY' ), '091426    '),
    ('*DMYY','*MDYY', 14092026, getDate(14092026, '*DMYY', '*MDYY'), '09142026  '),
    ('*DMYY','*DMY' , 14092026, getDate(14092026, '*DMYY', '*DMY' ), '140926    '),
    ('*DMYY','*DMYY', 14092026, getDate(14092026, '*DMYY', '*DMYY'), '14092026  '),
    ('*DMYY','*ISO' , 14092026, getDate(14092026, '*DMYY', '*ISO' ), '2026-09-14'),
    -- Error: invalid input format
    ('*XXX' ,'*YYMD', 20260914, getDate(20260914, '*XXX' , '*YYMD'), '*ERR      '),
    -- Error: invalid output format
    ('*YYMD','*XXX' , 20260914, getDate(20260914, '*YYMD', '*XXX' ), '*ERR      '),
    -- Error: both formats invalid
    ('*XXX' ,'*XXX' , 20260914, getDate(20260914, '*XXX' , '*XXX' ), '*ERR      '),
    -- Error: empty input format
    (''     ,'*YYMD', 20260914, getDate(20260914, ''     , '*YYMD'), '*ERR      '),
    -- Error: empty output format
    ('*YYMD',''     , 20260914, getDate(20260914, '*YYMD', ''     ), '*ERR      '),
    -- Valid date: year 99 month 09 day 14 in *YMD -> 1999-09-14
    ('*YMD' ,'*YYMD',   990914, getDate(  990914, '*YMD' , '*YYMD'), '19990914  '),
    -- Error: invalid month (month 13) in *YMD -> *ERR
    ('*YMD' ,'*YYMD',   261399, getDate(  261399, '*YMD' , '*YYMD'), '*ERR      '),
    -- Error: invalid month (month 13) in *DMY -> *ERR
    ('*DMY' ,'*YYMD',   141326, getDate(  141326, '*DMY' , '*YYMD'), '*ERR      '),
    -- Error: invalid month (month 13) in *MDY -> *ERR
    ('*MDY' ,'*YYMD',   131426, getDate(  131426, '*MDY' , '*YYMD'), '*ERR      '),
    -- Error: invalid day (day 32) in *YMD -> *ERR
    ('*YMD' ,'*YYMD',   263209, getDate(  263209, '*YMD' , '*YYMD'), '*ERR      '),
    -- Error: invalid day (day 32) in *DMY -> *ERR
    ('*DMY' ,'*YYMD',   320926, getDate(  320926, '*DMY' , '*YYMD'), '*ERR      '),
    -- Error: invalid day (day 32) in *MDY -> *ERR
    ('*MDY' ,'*YYMD',   093226, getDate(  093226, '*MDY' , '*YYMD'), '*ERR      ')
) AS T(IN_FMT, OUT_FMT, INPUT_NUM, RESULT, EXPECTED)
)
SELECT * FROM A
ORDER BY INPUT_FORMAT, OUTPUT_FORMAT
;
