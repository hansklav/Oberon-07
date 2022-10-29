MODULE Out1;  (** IN V5 *)  (* Martin Reiser 1992 / ETH 2003 / hk 2015, 2019 *)
(** 
	In Oberon System standard output (without Out1.Open) is to the System.Log text.
	After Out1.Open the output is to Out.Text in a newly opened text viewer.

	The default semantics is the same as in the original 1992 version of Out.Mod: all procedures 
	append immediately to the end of the text stream. If desired this could be changed with
	a call to Out1.Immediate(FALSE), but then don't forget a terminating Out1.Ln.

	Use Out1.SetFont to easily change the font programmatically.
	
	Remark:
	In the Oberon System Out uses a Writer from module Texts to write output to a text stream. 
	The original 1992 implementation writes the output immediately after every procedure call. 
	This rarely is a problem and some programs depend on this behaviour of Out. 
	Output can be made faster (at the expense of compatibility with other implementations)
	by delaying the writing of the buffer until a call to Out.Ln; this can be achieved by calling 
	Out1.Immediate(FALSE).
	For best performance use the Write procedures of Texts directly, as is done in N. Wirth's books.

	Solutions to some small problems (Oberon V5):
	After a call to Out.Open or Out1.Open output is to a newly opened text viewer. 
	If you close this viewer then all further output will be lost; in that case just activate 
	command Out.Open again by middle clicking on it somewhere in a text; this will open a new 
	TextViewer with an empty Out.Text.
	After a call to Out.Open only unloading Out (System.Free ... Out ~ ) can interactively 
	redirect the output stream to the System.Log text; therefore I added command Out1.ToLog 
	which does this more easily.

*)

	IMPORT Input, Fonts, Texts, Oberon, MenuViewers, TextFrames;
	
	CONST
		name = "Out.Text";
		menu = "System.Close System.Copy System.Grow Edit.Search Edit.Store";

	VAR
		T: Texts.Text;
		W: Texts.Writer;
		immediate*: BOOLEAN;

	PROCEDURE Append; 
	BEGIN
		IF immediate THEN Texts.Append(T, W.buf) END
	END Append;

	PROCEDURE Open* ;
	(** Open a separate viewer for output *)
		VAR
			x, y, X, Y: INTEGER;	keys: SET;
			menuF, mainF: TextFrames.Frame;
			V: MenuViewers.Viewer;
	BEGIN
		T := TextFrames.Text(name);
		menuF := TextFrames.NewMenu(name, menu);
		mainF := TextFrames.NewText(T, T.len - 200);
		Input.Mouse(keys, X, Y);																							   	   (* hk 2015 *)
		Oberon.AllocateUserViewer(X, x, y);
		V := MenuViewers.New(menuF, mainF, TextFrames.menuH, x, y)
	END Open;

	PROCEDURE Char* (ch: CHAR);
	(** Write the character ch to the end of the output stream *)
	BEGIN	 
		Texts.Write(W, ch); Append
	END Char;

	PROCEDURE String* (str: ARRAY OF CHAR);
	(** Write character string str to the end of the output stream *)
	BEGIN
		Texts.WriteString(W, str); Append
	END String;

	PROCEDURE Real* (x: REAL; n: INTEGER);
	(** Write the real x in n field positions *)
	BEGIN
		Texts.WriteReal(W, x, n); Append
	END Real;

	PROCEDURE RealFix* (x: REAL; n, f: INTEGER);
	(** Write the real x in n field positions in fixed point notation with f fraction digits *)	
	BEGIN
		Texts.WriteRealFix(W, x, n, f); Append
	END RealFix;
	
	PROCEDURE Int* (i, n: INTEGER);
	(** Write the integer i in n field positions *)
	BEGIN
		Texts.WriteInt(W, i, n); Append
	END Int;

	PROCEDURE Hex* (i: LONGINT);
	(** Write the integer i in hexadecimal with a leading space *)
	BEGIN
		Texts.WriteHex(W, i); Append
	END Hex;

	PROCEDURE Ln*;
	(** Write an end-of-line (CR) to the end of the buffer and then
	    unconditionally write the buffer to the end of the output stream *)
	BEGIN
		Texts.WriteLn(W); Texts.Append(T, W.buf)
	END Ln;

	PROCEDURE ToLog*;																													 (* hk 2016 *)
	(** Redirect the output stream to the System Log *)
	BEGIN
		T := Oberon.Log
	END ToLog;

	PROCEDURE Immediate* (on: BOOLEAN);                                                                          (* hk 2016 *)
	(** Only call this procedure with on = FALSE if you find the default output too slow *)                                 
	BEGIN 
		immediate := on
	END Immediate;

	PROCEDURE SetFont* (fontName: ARRAY OF CHAR);                                                                (* hk 2019 *)
	(** Change the screen font, e.g. SetFont("Courier10.Fnt") or SetFont("Oberon10.Scn.Fnt") *)
	BEGIN
		Texts.SetFont(W, Fonts.This(fontName))
	END SetFont;

BEGIN
	Texts.OpenWriter(W);  T := Oberon.Log;  
	immediate := TRUE
END Out1.
