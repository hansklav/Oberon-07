MODULE In; (* IN V5 *)	 (* Martin Reiser 1992 / hk 2015 *)
(** 
	Stream-oriented input from a text 
	From: M. Reiser & N. Wirth, Programming in Oberon. Addison-Wesley, 1992.
 *)

	IMPORT Texts, Viewers, Oberon, TextFrames;

	TYPE
		String32 = ARRAY 32 OF CHAR;																						 (* hk 2015 *)

	VAR
		T: Texts.Text;	S: Texts.Scanner;	 W: Texts.Writer;
		beg: LONGINT;
		Done*: BOOLEAN;

	PROCEDURE Put(txt: ARRAY OF CHAR);	(* write txt to the System.Log viewer *)
	BEGIN
		Texts.WriteString(W, txt);	Texts.WriteLn(W);	 Texts.Append(Oberon.Log, W.buf)
	END Put;

	PROCEDURE Open*;
		VAR	 
			end, time: LONGINT;
			V: Viewers.Viewer;
	BEGIN
		Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);	Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") OR (S.c = "@") THEN
			(* start input stream at beginning of selection, ^ for filenames, @ otherwise *)
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN	 Texts.OpenScanner(S, T, beg);	Done := ~S.eot;
			ELSE Put("No selection");  Done := FALSE
			END
		ELSIF (S.class = Texts.Char) & (S.c = "*") THEN
			(* start input stream at beginning of text in marked viewer *)
			V := Oberon.MarkedViewer();
(*		IF ~Oberon.Pointer.on THEN Put("Pointer not visible");	Done := FALSE 
			 ELS.. *)																															 (* hk 2015 *)
			IF (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
				T := V.dsc.next(TextFrames.Frame).text;	 beg := 0;
				Texts.OpenScanner(S, T, beg);	 Done := ~S.eot;
			ELSE	Put("Marked viewer not a text viewer");	 Done := FALSE
			END
		ELSE
			(* start input stream after command name *)
			T := Oberon.Par.text;	 beg := Oberon.Par.pos;
			Texts.OpenScanner(S, T, beg);	 Done := ~S.eot;
		END
	END Open;

	PROCEDURE Char* (VAR ch: CHAR);
	BEGIN
		IF Done THEN	ch := S.nextCh;	 Done := ~S.eot;	Texts.Read(S, S.nextCh)	 END
	END Char;

	PROCEDURE Int* (VAR i: INTEGER);
	BEGIN
		IF Done THEN	Texts.Scan(S);	i := S.i;	 Done := (S.class = Texts.Int)	END
	END Int;

	PROCEDURE Real* (VAR x: REAL);
	BEGIN
		IF Done THEN	Texts.Scan(S);	x := S.x;	 Done := (S.class = Texts.Real)	 END
	END Real;

	PROCEDURE Name* (VAR nme: String32 (* ARRAY OF CHAR *)	);								 (* hk 2015 *)
	(* Read name such as Syntax.Scn.Fnt from input stream *)
	BEGIN	 
		IF Done THEN	Texts.Scan(S);	nme := S.s;	 Done := (S.class = Texts.Name)	 END
	END Name;

	PROCEDURE String* (VAR str: ARRAY OF CHAR);
	(* Read blank delimited character sequence *)
		CONST	 CR = 0DX;	NUL = 0X;
		VAR	 ch: CHAR;	j: LONGINT;
	BEGIN			
		IF Done THEN
			REPEAT	Char(ch)	UNTIL ((ch # " ") & (ch # CR)) OR ~Done;
			j := 0;
			WHILE Done & (ch # " ") & (ch # CR) DO
				IF j < LEN(str) - 1 THEN str[j] := ch;	INC(j)	END;
				Char(ch)
			END;
			str[j] := NUL;	Done := j # 0
		END
	END String;

BEGIN	 
	Texts.OpenWriter(W);  Done := FALSE
END In.
