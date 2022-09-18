MODULE Out; (* IN V5 *)	 (* Martin Reiser 1992 / hk 2015 *)
(**
	Stream-oriented text output.
	Port of the original 1992 version.

	In Oberon System standard output (without Out.Open) is to the System.Log text.

	Remark:
	In Oberon System module Out uses a Writer from module Texts to write output to a text. 
	Because Texts.Append(T, W.buf) updates the text immediately after every procedure call
	sometimes this makes writing relatively slow. This rarely is a problem, but if it is 
	then use 'IMPORT Out := Out1' and call Out.Immediate(FALSE); see my module Out1.
	For best performance use the Write procedures of module Texts directly, as Wirth shows 
	in his 'Programming, A Tutorial', https://people.inf.ethz.ch/wirth/Oberon/PIO.pdf

	Problem:
	In Oberon System after a call to Out.Open output is to a newly opened TextViewer 'Out.Text'.
	If you close this viewer then all further output will be lost; in that case just 
	activate command Out.Open again by middle clicking on it somewhere in a text; this 
	will open a new TextViewer with an empty Out.Text.
	After a call to Out.Open only unloading Out (System.Free ... Out ~ ) can interactively 
	redirect the output stream to the System.Log text; therefore in module Out1 I added 
	command Out1.ToLog which does this more easily.
*)

	IMPORT Input, Texts, Oberon, MenuViewers, TextFrames;

	VAR
		T: Texts.Text;	(* output text *)
		W: Texts.Writer;

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
	Texts.OpenWriter(W);  T := Oberon.Log
END Out.
