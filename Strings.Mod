MODULE Strings;  (* Oakwood version + Copy *)
(**
  See: The Oakwood Guidelines for Oberon-2 Compiler Developers:
  http://www.math.bas.bg/bantchev/place/oberon/oakwood-guidelines.pdf
  http://www.edm2.com/index.php/The_Oakwood_Guidelines_for_Oberon-2_Compiler_Developers

  This implementation inspired by the OBNC library module Strings.obn (https://miasap.se/obnc)
  
  Note: All strings MUST be 0X terminated.

  Procedure 'Copy' is an extension of the Oakwood version, useful since COPY is no longer predeclared
  and  s1 := s0 gives error message "illegal assignment" if LEN(s0) # LEN(s1), even if Length(s0) < LEN(s1).
*)

  PROCEDURE MIN(i, j: INTEGER): INTEGER;
  BEGIN 
    IF i > j THEN i := j END
  RETURN i
  END MIN;

  PROCEDURE Length* (s: ARRAY OF CHAR): INTEGER;
  (** Length(s) returns the number of characters in s up to and excluding the first 0X.
  *)
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO INC(i) END;
    ASSERT(i < LEN(s))
  RETURN i
  END Length;
  
  PROCEDURE Copy* (source: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
  (** Copy(src, dst) assigns src to dst without the strict type check of dest := src.
    It has the same effect as Delete(dst, 0, Length(dst)) followed by Insert(src, 0, dst)
    or as  dst := "";  Insert(src, 0, dst).
  *)
    VAR i, j, max: INTEGER;
  BEGIN
    i := 0; max := LEN(dest);
    WHILE (source[i] # 0X) & (i < max - 1) DO dest[i] := source[i]; INC(i) END;
    dest[i] := 0X
  END Copy;

  PROCEDURE Insert* (source: ARRAY OF CHAR; pos: INTEGER; VAR dest: ARRAY OF CHAR);
  (** Insert(src, pos, dst) inserts the string src into the string dst at position pos 
    (0 <= pos <= Length(dst)). If pos = Length(dst), src is appended to dst. 
    If the size of dst is not large enough to hold the result of the operation, 
    the result is truncated so that dst is always terminated with 0X. 
  *)
    VAR i, lim, sLen, dLen, len: INTEGER;
  BEGIN sLen := Length(source);  dLen := Length(dest);
    ASSERT(pos >= 0); ASSERT(pos <= dLen);  
    len := MIN(dLen + sLen, LEN(dest) - 1);
    dest[len] := 0X;
    FOR i := len - 1 TO pos + sLen BY -1 DO dest[i] := dest[i - sLen] END;  (* move chars of dest *)
    lim := MIN(pos + sLen - 1, len - 1);
    FOR i := pos TO lim DO dest[i] := source[i - pos] END  (* insert source into dest *)
  END Insert;
  
  PROCEDURE Append* (extra: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
  (** Append(s, dst) has the same effect as Insert(s, Length(dst), dst).
  *)
    VAR i, d0, d1: INTEGER;
  BEGIN
    d0 := Length(dest);  (* original length of dest *)
    d1 := MIN(d0 + Length(extra), LEN(dest) - 1);  (* new length of dest *)
    FOR i := d0 TO d1 - 1 DO dest[i] := extra[i - d0] END;
    dest[d1] := 0X
  END Append;
  
  PROCEDURE Delete* (VAR s: ARRAY OF CHAR; pos, n: INTEGER);
  (** Delete(s, pos, n) deletes n characters from s starting at position pos 
    (0 <= pos Length(s)). If n > Length(s) - pos, the new length of s is pos.
  *)
    VAR len, i, j: INTEGER;
  BEGIN len := Length(s);
    ASSERT(pos >= 0); ASSERT(pos <= len); ASSERT(n >= 0);
    j := MIN(n, len - pos);  (* remove j chars *)
    FOR i := pos TO len - j DO s[i] := s[i + j] END
  END Delete;

  PROCEDURE Replace* (source: ARRAY OF CHAR; pos: INTEGER; VAR dest: ARRAY OF CHAR);
  (** Replace(src, pos, dst) has the same effect as Delete(dst, pos, Length(src)) followed 
    by Insert(src, pos, dst).
  *)
    VAR len, i, j: INTEGER;
  BEGIN len := Length(dest);
    ASSERT(pos >= 0); ASSERT(pos <= len);
    j := MIN(Length(source), LEN(dest) - 1 - pos);  (* replace j chars *)
    FOR i := 0 TO j - 1 DO dest[pos + i] := source[i] END;
    IF pos + j > len THEN dest[pos + j] := 0X END
  END Replace;
  
  PROCEDURE Extract* (source: ARRAY OF CHAR; pos, n: INTEGER; VAR dest: ARRAY OF CHAR);
  (** Extract(src, pos, n, dst) extracts a substring dst with n characters from 
    position pos (0 <=pos Length(src)) in src. If n > Length(src) - pos, dst is 
    only the part of src from pos to the end of src, i.e. Length(src) -1. 
    If the size of dst is not large enough to hold the result of the operation, 
    the result is truncated so that dst is always terminated with a 0X.
  *)
    VAR len, i, j: INTEGER;
  BEGIN 
    len := Length(source);
    ASSERT(pos >= 0); ASSERT(pos <= len);
    j := MIN(n, MIN(len - pos, LEN(dest) - 1)); (* extract j chars *)
    FOR i := 0 TO j - 1 DO dest[i] := source[pos + i] END;
    dest[j] := 0X   
  END Extract;

  PROCEDURE Pos* (pattern, s: ARRAY OF CHAR; pos: INTEGER): INTEGER;
  (** Pos(pat, s, pos) returns the position of the first occurrence of pat in s. 
    Searching starts at position pos. If pat is not found, -1 is returned.
  *)
    VAR res, pLen, len: INTEGER;

    PROCEDURE Found (pattern: ARRAY OF CHAR; len: INTEGER; s: ARRAY OF CHAR; pos: INTEGER): BOOLEAN;
      VAR i: INTEGER;
    BEGIN i := 0;
      WHILE (i < len) & (pattern[i] = s[pos + i]) DO INC(i) END
    RETURN i = len
    END Found;

  BEGIN len := Length(s);
    ASSERT(pos >= 0); ASSERT(pos <= len);
    res := -1;
    IF pattern # "" THEN
      pLen := Length(pattern);
      DEC(pos);
      REPEAT
        INC(pos); WHILE (pos + pLen <= len) & (s[pos] # pattern[0]) DO INC(pos) END
      UNTIL (pos + pLen > len) OR Found(pattern, pLen, s, pos);
      IF pos + pLen <= len THEN res := pos END
    END;
    ASSERT(res >= -1); ASSERT(res < len)
  RETURN res
  END Pos;

  PROCEDURE Cap* (VAR s: ARRAY OF CHAR);
  (** Cap(s) replaces each lower case letter within s by its upper case equivalent.
  *)
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO
      IF ("a" <= s[i]) & (s[i] <= "z") THEN
        s[i] := CHR(ORD(s[i]) - 20H)
	 (* ELSIF s[i] = "ö" THEN s[i] := "Ö"
      ELSIF s[i] = ... THEN s[i] := ... *)
      ELSE
      END;
      INC(i)
    END
  END Cap;

END Strings.
