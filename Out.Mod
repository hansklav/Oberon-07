MODULE Out; (* IN V5 *)	 (* Martin Reiser 1992 / hk 2015 *)
(**
	Stream-oriented text output.
	Port of the original 1992 version.

	In Oberon System standard output (without Out.Open) is to the System.Log text.

	Remark:
	Out uses a Writer from module Texts to write output to a text. This can make
	writing relatively slow because the text is updated after every procedure call. This 
	rarely is a problem, but if it is use 'Out := Out1' with Out1.immediate set to FALSE
	by calling Out1.Immediate(FALSE).
	For best performance use the Write procedures of Texts directly.

	Problem (Oberon V5):
	After a call to Out.Open output is to a newly opened TextViewer; don't
	close this TextViewer because then all further output will be lost.
	In that case only unloading Out (System.Free ... Out~) can redirect the
	output stream to the System.Log. Therefore in module Out1 I added 
	command Out.ToLog which redirects the output stream to the System.Log.
*)

	IMPORT Input, Texts, Oberon, MenuViewers, TextFrames;

	VAR
		T: Texts.Text;	(* output text *)
		W: Texts.Writer;
		immediate*: BOOLEAN;

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
		Input.Mouse(keys, X, Y);																								 (* hk 2015 *)
		Oberon.AllocateUserViewer(X, x, y);
		V := MenuViewers.New(menuF, mainF, TextFrames.menuH, x, y)
	END Open;

	PROCEDURE Char* (ch: CHAR);
	BEGIN	 
		Texts.Write(W, ch);  Texts.Append(T, W.buf)
	END Char;

	PROCEDURE String* (str: ARRAY OF CHAR);
	BEGIN
		Texts.WriteString(W, str);  Texts.Append(T, W.buf)
	END String;

	PROCEDURE Real* (x: REAL; n: INTEGER);
	BEGIN
		Texts.WriteReal(W, x, n);  Texts.Append(T, W.buf)
	END Real;
	
	PROCEDURE Int* (i, n: INTEGER);
	BEGIN
		Texts.WriteInt(W, i, n);  Texts.Append(T, W.buf)
	END Int;

	PROCEDURE Ln*;
	BEGIN
		Texts.WriteLn(W);  Texts.Append(T, W.buf)
	END Ln;

BEGIN
	Texts.OpenWriter(W);  T := Oberon.Log;  immediate := FALSE
END Out.
