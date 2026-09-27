**FREE
// ============================================================
// Program  : UDF001
// Type     : *SRVPGM  (ILE RPG, full free-format)
// Purpose  : Implements the SQL UDF getDate (overloaded).
//            Converts a date value to CHAR(10) in the
//            requested output format, by calling QWCCVTDT.
//
// Exported procedures:
//   getDateD  - input: DATE,         output format token
//               output: CHAR(10)
//   getDateN  - input: NUMERIC(8,0), input + output format tokens
//               output: CHAR(10)
//
// Internal (non-exported) procedure:
//   callCvtdt - single wrapper around the QWCCVTDT API call.
//
// Supported format tokens:
//   Input  : *YMD *YYMD *MDY *MDYY *DMY *DMYY
//   Output : *YMD *YYMD *MDY *MDYY *DMY *DMYY *ISO
//
// Notes:
//   - QWCCVTDT does not accept *ISO: when output is *ISO the API
//     is called with *YYMD, then YYYY-MM-DD is built manually.
//   - When input is a DATE and output is *ISO, %CHAR(date:*ISO)
//     is returned directly — no API call needed.
//   - Output with 2-digit year (*YMD, *MDY, *DMY) returns 6 chars;
//     output *ISO returns 10 chars; all others return 8 chars.
//     All results are left-justified in CHAR(10).
//   - On any error, '*ERR' is returned and a *INFO message is
//     written to the job log via SND-MSG.
//   - errDS.bytPrv must be 272 before each API call so that
//     QWCCVTDT returns errors in the DS instead of raising an
//     escape message.
// ============================================================

CTL-OPT NOMAIN OPTION(*SRCSTMT : *NODEBUGIO);

// ------------------------------------------------------------
// Error handling strategy:
//   Each exported procedure wraps its entire body in a
//   MONITOR / ON-ERROR / ENDMON block so that any unhandled
//   RPG exception (including unexpected escape messages not
//   caught by errDS) is intercepted and '*ERR' is returned
//   instead of propagating to SQL as error SQL0443.
//   SND-MSG *INFO writes the status to the job log in every
//   error path so the cause can be investigated.
// ------------------------------------------------------------

// ------------------------------------------------------------
// Prototype: QWCCVTDT (Convert Date and Time Format - QSYS)
// Format parameters are CHAR(10): RPG auto-pads shorter
// literals with blanks, so '*YYMD' is valid (same as '*YYMD    ').
// ------------------------------------------------------------
DCL-PR qwccvtdt EXTPGM('QWCCVTDT');
  inFmt  CHAR(10)        CONST;
  inVar  CHAR(32)        CONST;
  outFmt CHAR(10)        CONST;
  outVar CHAR(32);
  errDS  LIKEDS(t_errDS);
END-PR;

// ------------------------------------------------------------
// Prototype: callCvtdt (internal wrapper — not exported)
// ------------------------------------------------------------
DCL-PR callCvtdt;
  inFmt  CHAR(10)  CONST;
  inVar  CHAR(32)  CONST;
  outFmt CHAR(10)  CONST;
  outVar CHAR(32);
  msgId  CHAR(7);
  msgDat CHAR(252);
END-PR;

// ------------------------------------------------------------
// Error code data structure ERRC0100 (272 bytes).
// ------------------------------------------------------------
DCL-DS t_errDS QUALIFIED TEMPLATE;
  bytPrv  INT(10);
  bytAvl  INT(10);
  msgId   CHAR(7);
  filler  CHAR(1);
  msgData CHAR(252);
END-DS;

// Valid format lists for %SCAN validation
DCL-C c_validIn  '*YMD|*YYMD|*MDY|*MDYY|*DMY|*DMYY';
DCL-C c_validOut '*YMD|*YYMD|*MDY|*MDYY|*DMY|*DMYY|*ISO';

// 6-digit formats (input and output):
//   Input : QWCCVTDT expects 7 bytes = 1 century byte ('0'=1900s,'1'=2000s)
//           followed by 6 zero-padded digits. e.g. *DMY 14/09/26 -> '1140926'
//   Output: QWCCVTDT returns 7 bytes (same layout); century byte must be
//           skipped on read: use %SUBST(outVar:2:6).
// 8-digit formats (input and output):
//   Input : QWCCVTDT expects exactly 8 zero-padded digits.
//   Output: QWCCVTDT returns 8 bytes: use %SUBST(outVar:1:8).
DCL-C c_fmt6     '*YMD|*MDY|*DMY';

// ============================================================
// Procedure : getDateD  (EXPORT)
// Purpose   : Convert a SQL DATE to CHAR(10) in the requested
//             output format.
//             If output is *ISO, %CHAR(date:*ISO) is returned
//             directly — no API call needed.
//             Otherwise the DATE is serialised as YYYYMMDD and
//             passed to QWCCVTDT as *YYMD.
// Parameters: inDate  - date to convert
//             outFmt  - output format token (e.g. '*DMY')
// Returns   : CHAR(10), or '*ERR' on error
// ============================================================
DCL-PROC getDateD EXPORT;
  DCL-PI *N CHAR(10);
    inDate DATE     CONST;
    outFmt CHAR(10) CONST;
  END-PI;

  DCL-S  yymdStr  CHAR(32)  INZ(*BLANKS);
  DCL-S  outVar   CHAR(32)  INZ(*BLANKS);
  DCL-S  msgId    CHAR(7)   INZ(*BLANKS);
  DCL-S  msgDat   CHAR(252) INZ(*BLANKS);
  DCL-S  pDateOut CHAR(10)  INZ('*ERR');

  MONITOR;

    // Validate output format
    IF %SCAN(%TRIM(outFmt) : c_validOut) = 0;
      SND-MSG *INFO 'UDF001 getDateD: invalid output format ' + %TRIM(outFmt);
      RETURN pDateOut;
    ENDIF;

    // If output is *ISO, return the date as-is via %CHAR — no API needed
    IF %TRIM(outFmt) = '*ISO';
      pDateOut = %CHAR(inDate : *ISO);
      RETURN pDateOut;
    ENDIF;

    // Serialise DATE to YYYYMMDD (*YYMD for QWCCVTDT)
    yymdStr = %CHAR(inDate : *ISO0);

    // Call QWCCVTDT via internal wrapper: *YYMD -> requested output format
    callCvtdt('*YYMD' : yymdStr : outFmt : outVar : msgId : msgDat);

    IF msgId <> *BLANKS;
      SND-MSG *INFO 'UDF001 getDateD API error: ' + %TRIM(msgId)
                  + ' ' + %TRIM(msgDat);
      RETURN pDateOut;
    ENDIF;

    // QWCCVTDT output layout:
    //   6-digit formats (*YMD *MDY *DMY)   -> byte 1 = century, bytes 2-7 = date
    //   8-digit formats (*YYMD *MDYY *DMYY) -> bytes 1-8 = date
    SELECT;
      WHEN %SCAN(%TRIM(outFmt) : c_fmt6) > 0;
        pDateOut = %SUBST(outVar : 2 : 6);
      OTHER;
        pDateOut = %SUBST(outVar : 1 : 8);
    ENDSL;

  ON-ERROR;
    SND-MSG *INFO 'UDF001 getDateD: unhandled exception, returning *ERR';

  ENDMON;

  RETURN pDateOut;

END-PROC;

// ============================================================
// Procedure : getDateN  (EXPORT)
// Purpose   : Convert a NUMERIC(8,0) date to CHAR(10) in the
//             requested output format.
//             If output is *ISO, the API is called with *YYMD
//             and the result is formatted as YYYY-MM-DD.
//             Otherwise the API is called directly with outFmt.
// Parameters: inNum   - date as numeric (e.g. 20260914 for *YYMD)
//             inFmt   - input format token  (e.g. '*YYMD')
//             outFmt  - output format token (e.g. '*DMY')
// Returns   : CHAR(10), or '*ERR' on error
// ============================================================
DCL-PROC getDateN EXPORT;
  DCL-PI *N CHAR(10);
    inNum  ZONED(8 : 0) CONST;
    inFmt  CHAR(10)     CONST;
    outFmt CHAR(10)     CONST;
  END-PI;

  DCL-S  numStr    CHAR(32)  INZ(*BLANKS);
  DCL-S  outVar    CHAR(32)  INZ(*BLANKS);
  DCL-S  msgId     CHAR(7)   INZ(*BLANKS);
  DCL-S  msgDat    CHAR(252) INZ(*BLANKS);
  DCL-S  pDateOut  CHAR(10)  INZ('*ERR');
  DCL-S  apiOutFmt CHAR(10)  INZ(*BLANKS);
  DCL-S  yymd8     CHAR(8)   INZ(*BLANKS);

  MONITOR;

    // Validate input format (*ISO not accepted for numeric input)
    IF %SCAN(%TRIM(inFmt) : c_validIn) = 0;
      SND-MSG *INFO 'UDF001 getDateN: invalid input format ' + %TRIM(inFmt);
      RETURN pDateOut;
    ENDIF;

    // Validate output format
    IF %SCAN(%TRIM(outFmt) : c_validOut) = 0;
      SND-MSG *INFO 'UDF001 getDateN: invalid output format ' + %TRIM(outFmt);
      RETURN pDateOut;
    ENDIF;

    // Build the input string for QWCCVTDT:
    //   6-digit formats: 7 bytes = century ('0' 1900s / '1' 2000s) + 6 digits
    //     %EDITC(ZONED(8:0):'X') -> '00DDMMYY' or '00YYMMDD' etc. (8 chars)
    //     century byte derived from the 2 leading digits of the 8-digit form:
    //     if %SUBST(numStr:1:2) >= '20' then century = '1' else '0'
    //   8-digit formats: 8 bytes = straight zero-padded digits
    numStr = %EDITC(inNum : 'X');
    SELECT;
      WHEN %SCAN(%TRIM(inFmt) : c_fmt6) > 0;
        // Derive century from the 4-digit year embedded in the 8-char picture.
        // For *YMD the layout is YYDDMM... actually the numeric value stored
        // by the caller already encodes only 6 significant digits (e.g. 140926).
        // %EDITC gives '00140926'; the century byte is computed from the last
        // 2 digits of the year position — but we cannot know the year here.
        // Convention: pass century '1' for 2000s, '0' for 1900s.
        // Since the caller stores a 6-digit value, the year sits in the last 2
        // digits of the numeric. We extract them per format:
        //   *DMY -> DDMMYY -> year = positions 5-6 of the 6-digit string
        //   *MDY -> MMDDYY -> year = positions 5-6
        //   *YMD -> YYMMDD -> year = positions 1-2
        // From the 8-char %EDITC string (00DDMMYY or 00YYMMDD):
        //   *DMY / *MDY : year digits at positions 7-8
        //   *YMD        : year digits at positions 3-4
        IF %TRIM(inFmt) = '*YMD';
          // year at bytes 3-4 of 8-char picture (e.g. '00260914' -> '26')
          IF %SUBST(numStr : 3 : 2) >= '50';
            numStr = '0' + %SUBST(numStr : 3 : 6);  // 1950-1999
          ELSE;
            numStr = '1' + %SUBST(numStr : 3 : 6);  // 2000-2049
          ENDIF;
        ELSE;
          // *DMY / *MDY: year at bytes 7-8 of 8-char picture (e.g. '00140926' -> '26')
          IF %SUBST(numStr : 7 : 2) >= '50';
            numStr = '0' + %SUBST(numStr : 3 : 6);  // 1950-1999
          ELSE;
            numStr = '1' + %SUBST(numStr : 3 : 6);  // 2000-2049
          ENDIF;
        ENDIF;
      OTHER;
        // 8-digit formats: numStr already holds 8 zero-padded digits
    ENDSL;

    // If output is *ISO, ask API for *YYMD and format manually
    IF %TRIM(outFmt) = '*ISO';
      apiOutFmt = '*YYMD';
    ELSE;
      apiOutFmt = outFmt;
    ENDIF;

    // Call QWCCVTDT via internal wrapper
    callCvtdt(inFmt : numStr : apiOutFmt : outVar : msgId : msgDat);

    IF msgId <> *BLANKS;
      SND-MSG *INFO 'UDF001 getDateN API error: ' + %TRIM(msgId)
                  + ' ' + %TRIM(msgDat);
      RETURN pDateOut;
    ENDIF;

    // QWCCVTDT output layout:
    //   *ISO (via *YYMD)                   -> bytes 1-8 = YYYYMMDD -> YYYY-MM-DD
    //   6-digit formats (*YMD *MDY *DMY)   -> byte 1 = century, bytes 2-7 = date
    //   8-digit formats (*YYMD *MDYY *DMYY) -> bytes 1-8 = date
    SELECT;
      WHEN %TRIM(outFmt) = '*ISO';
        yymd8    = %SUBST(outVar : 1 : 8);
        pDateOut = %SUBST(yymd8 : 1 : 4) + '-'
                 + %SUBST(yymd8 : 5 : 2) + '-'
                 + %SUBST(yymd8 : 7 : 2);
      WHEN %SCAN(%TRIM(outFmt) : c_fmt6) > 0;
        pDateOut = %SUBST(outVar : 2 : 6);
      OTHER;
        pDateOut = %SUBST(outVar : 1 : 8);
    ENDSL;

  ON-ERROR;
    SND-MSG *INFO 'UDF001 getDateN: unhandled exception, returning *ERR';

  ENDMON;

  RETURN pDateOut;

END-PROC;

// ============================================================
// Procedure : callCvtdt  (NOT EXPORTED — internal only)
// Purpose   : Single wrapper around the QWCCVTDT API call.
//             Initialises the error DS, calls the API, and
//             returns the output string via outVar.
//             On API error, msgId and msgDat are populated.
// ============================================================
DCL-PROC callCvtdt;
  DCL-PI *N;
    inFmt  CHAR(10)  CONST;
    inVar  CHAR(32)  CONST;
    outFmt CHAR(10)  CONST;
    outVar CHAR(32);
    msgId  CHAR(7);
    msgDat CHAR(252);
  END-PI;

  DCL-DS errDS LIKEDS(t_errDS) INZ(*LIKEDS);

  // Reset outputs and error DS before each call
  outVar        = *BLANKS;
  msgId         = *BLANKS;
  msgDat        = *BLANKS;
  errDS.bytPrv  = 272;
  errDS.msgId   = *BLANKS;
  errDS.msgData = *BLANKS;

  QWCCVTDT(inFmt : inVar : outFmt : outVar : errDS);

  msgId  = errDS.msgId;
  msgDat = errDS.msgData;

END-PROC;
