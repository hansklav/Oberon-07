MODULE Out; (** IN V5 *)	 (* Martin Reiser 1992 / ETH 2003 / hk 2015, 2019, 2023 *)
(** 
	Stream-oriented text output.
	Port with later ETH additions and printf by Joerg Straube.

	In Oberon System standard output (without Out.Open) is to the System.Log text.

	Remark:
	In Oberon System module Out uses a Writer from module Texts to write output to a text. 
	Because Texts.Append(T, W.buf) updates the text immediately after every procedure call
	sometimes this makes writing relatively slow. This rarely is a problem, and some modules
  might depend on this semantics, but if it is a problem call Out.SetImmediate(FALSE) once
	and conclude your output with Out.Ln to make it faster.
	For best performance use the Write procedures of module Texts directly, as Wirth shows 
	in his 'Programming, A Tutorial', https://people.inf.ethz.ch/wirth/Oberon/PIO.pdf

	Problem:
	In Oberon System after a call to Out.Open output is to a newly opened TextViewer 'Out.Text'.
	If you close this viewer then all further output will be lost; in that case just 
	activate command Out.Open again by middle clicking on it somewhere in a text; this 
	will open a new TextViewer with an empty Out.Text.
	After a call to Out.Open only unloading Out (System.Free ... Out ~ ) can interactively
	interactively redirect the output stream to the System.Log text. Therefore in this extended 
  module Out I added command Out.ToLog which does this more easily.
*)

	IMPORT Input, Fonts, Texts, Oberon, MenuViewers, TextFrames;

	CONST
		ordA = ORD("A");  ord0 = ORD("0");

	VAR
		T*: Texts.Text;  W: Texts.Writer;
		immediate*: BOOLEAN;

	PROCEDURE Append; 
	BEGIN
		IF immediate THEN Texts.Append(T, W.buf) END
	END Append;

	PROCEDURE Open*;
		VAR
			x, y, X, Y: INTEGER;	keys: SET;
			menuF, mainF: TextFrames.Frame;
			V: MenuViewers.Viewer;
	BEGIN
		T := TextFrames.Text("Out.Text");
		menuF := TextFrames.NewMenu("Out.Text",
			"System.Close System.Copy System.Grow Edit.Search Edit.Store");
		mainF := TextFrames.NewText(T, T.len - 200);
		Input.Mouse(keys, X, Y);																				
		Oberon.AllocateUserViewer(X, x, y);
		V := MenuViewers.New(menuF, mainF, TextFrames.menuH, x, y)
	END Open;

	PROCEDURE Char* (ch: CHAR);
	BEGIN	 
		Texts.Write(W, ch);  Append
	END Char;

	PROCEDURE String* (str: ARRAY OF CHAR);
	BEGIN
		Texts.WriteString(W, str);  Append
	END String;

	PROCEDURE Real* (x: REAL; n: INTEGER);
	BEGIN
		Texts.WriteReal(W, x, n);  Append
	END Real;

	PROCEDURE RealFix* (x: REAL; n, k: INTEGER);
	(** Write the real x in fixed point notation in at least n field positions 
		with (if possible) k digits after the decimal point. *)
	BEGIN
		Texts.WriteRealFix(W, x, n, k);  Append
	END RealFix;
	
	PROCEDURE Int* (i, n: INTEGER);
	BEGIN
		Texts.WriteInt(W, i, n);  Append
	END Int;

	PROCEDURE Hex* (i: INTEGER);
	(** Write the integer i in hexadecimal with a leading space. *)
	BEGIN
		Texts.WriteHex(W, i);  Append
	END Hex;

	PROCEDURE CharHex* (ch: CHAR);
	(** Write character ch in hexadecimal.
		Probably only correct for 7- or 8-bit character sets like ASCII, the first 128 code points of UTF-8, EBCDIC.
	*)
		VAR dig, i, x: INTEGER;  a: ARRAY 2 OF CHAR;
	BEGIN i := 0;  x := ORD(ch);
		REPEAT
			dig := x MOD 16;
			IF dig < 10 THEN a[i] := CHR(dig + ord0) ELSE a[i] := CHR(dig - 10 + ordA) END;
			x := x DIV 16; INC(i)
		UNTIL x = 0;
		IF a[i-1] >= "A" THEN Texts.Write(W, "0") END;
		REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0;
		Texts.Write(W, "X");
		Append
	END CharHex;

	PROCEDURE ByteHex* (b: BYTE; H: BOOLEAN);
	(** Write byte b as a two digit hexadecimal, optionally with three digits and a trailing "H" *)
		VAR dig, i, x: INTEGER;  a: ARRAY 2 OF CHAR;
	BEGIN i := 0;  x := b;
		REPEAT
			dig := x MOD 16;
			IF dig < 10 THEN a[i] := CHR(dig + ord0) ELSE a[i] := CHR(dig - 10 + ordA) END;
			x := x DIV 16; INC(i)
		UNTIL x = 0;
		IF H THEN Texts.Write(W, "0") END;
		IF b < 16 THEN Texts.Write(W, "0") END;
	(* IF a[i-1] >= "A" THEN Texts.Write(W, "0") END; *)
		REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0;
		IF H THEN Texts.Write(W, "H") END;		
		Append
	END ByteHex;

	PROCEDURE IntHex* (x: INTEGER);
	(** Write integer x in hexadecimal *)
		VAR dig, i, n: INTEGER;  a: ARRAY 32 OF CHAR;
	BEGIN
		Texts.WriteHex(W, x);  Texts.Write(W, "H");
		Append
	END IntHex;

	PROCEDURE RealHex* (x: REAL);
	(** Write the raw hexadecimal representation of REAL x *)
	BEGIN IntHex(ORD(x))
	END RealHex;

	PROCEDURE Bool* (b: BOOLEAN);
	(** Write the Boolean value b as T or F *)
	BEGIN 
		IF b THEN Char("T") ELSE Char("F") END
	END Bool;

	PROCEDURE Ln*;
	BEGIN
		Texts.WriteLn(W);  Texts.Append(T, W.buf)
	END Ln;

	PROCEDURE ToLog*;
	(** Redirect the output of module Out to the System.Log. 
      Use command Out.ToLog, and if needed System.OpenLog. *)
	BEGIN
		T := Oberon.Log
	END ToLog;

	PROCEDURE SetImmediate* (on: BOOLEAN);
	(** Only call this procedure with on = FALSE if you find the default output too slow *) 
	BEGIN
		immediate := on
	END SetImmediate;

	PROCEDURE SetFont* (fontName: ARRAY OF CHAR);
	(** Change the screen font, e.g. SetFont("Courier10.Fnt") or SetFont("Oberon10.Scn.Fnt") *)
	BEGIN
		Texts.SetFont(W, Fonts.This(fontName));
		Texts.Append(T, W.buf)
	END SetFont;

	(* https://lists.inf.ethz.ch/pipermail/oberon/2020/014666.html  (Joerg Straube) *)

	PROCEDURE printf* (s: ARRAY OF CHAR; i1, i2: INTEGER; str: ARRAY OF CHAR);
	(* supported format %[length]type, type = d, i, x or s, and escape characters \n, \t ;
		 escape characters \q and \hhX added by hk Oct 2023
	 *)
		VAR d, h, n, j, len, par, x: INTEGER; ch, nxCh: CHAR; imm: BOOLEAN;
	BEGIN
		imm := immediate; immediate := FALSE;
		par := 1; n := 0; ch := s[0];
		WHILE (ch # 0X) & (n < LEN(s)) DO
			j := n + 1; nxCh := s[j];
			IF ch = "%" THEN           (* handle format *)
				len := 0;
				WHILE ("0" <= nxCh) & (nxCh <= "9") DO 
					len := len * 10 + ORD(nxCh) - ORD("0"); INC(j); nxCh := s[j] 
				END;
				IF nxCh = "s" THEN String(str); INC(j)
				ELSIF (nxCh # "d") & (nxCh # "i") & (nxCh # "x") THEN Char("%")
				ELSE
					x := i2; IF par = 1 THEN x := i1 END; INC(par);
					IF nxCh = "x" THEN Hex(x) ELSE (* i, d *) Int(x, len) END;
					INC(j)
				END
			ELSIF ch = "\" THEN        (* handle escape characters *)
				IF nxCh = "n" THEN Ln; INC(j)
				ELSIF nxCh = "t" THEN Char(9X); INC(j)
				ELSIF nxCh = "q" THEN Char(22X); INC(j)  (* quotation mark *)
				ELSIF ("0" <= nxCh) & (nxCh <= "9") THEN  (* hex character *)
        			n := ORD(nxCh) - 30H; h := n; INC(j); nxCh := s[j];
					WHILE ("0" <= nxCh) & (nxCh <= "9") OR ("A" <= nxCh) & (nxCh <= "F") DO
						IF nxCh <= "9" THEN d := ORD(nxCh) - 30H ELSE d := ORD(nxCh) - 37H END;
						n := 10*n + d; h := 10H*h + d; INC(j); nxCh := s[j]
					END;
        			IF nxCh = "X" THEN Char(CHR(h)); INC(j) END
				ELSE Char("\")
				END
			ELSE
				Char(ch)
			END;
			n := j; ch := s[n]
		END;
		immediate := imm;
		Append                 (* hk  Oct 2023, to prevent partial output with more than one \n *)
	END printf;


	


BEGIN
	Texts.OpenWriter(W);  T := Oberon.Log;  immediate := TRUE
END Out.


MODULE TestOut;
	IMPORT Out;

	PROCEDURE Do*;
		CONST tab = 9X;
		VAR i: INTEGER;  ch: CHAR;
	BEGIN
		Out.SetFont("Courier10.Fnt");
		FOR i := 0 TO 255 DO 
			Out.Hex(i); Out.Char(tab);`
			Out.ByteHex(i, TRUE); Out.Char(tab); 
			Out.IntHex(i);  Out.Char(tab);
			Out.CharHex(CHR(i)); Out.Char(tab);
			Out.Char(CHR(i)); Out.Ln
		END; Out.Ln;

		Out.printf("%x = %d (%s)\n", i, i, "QED");
		Out.Hex(i); Out.String(" = "); Out.Int(i, 0); Out.String(" (QED)"); Out.Ln;

		Out.SetFont("Oberon10.Scn.Fnt");
		Out.printf("\qOh, you can't help that,\q said the Cat:\n\qWe're all mad here. I'm mad. You're mad.\q\n", i, i, "");
		Out.printf("\n\26X (%s)\n\t\23X\9XThe End.", i, i, "QED")
	END Do;

END TestOut.

TestOut.Do
Out.ToLog
