MODULE TestArctan; (* in V5 *)  (* hk 21-1-2023 *)
(* Test for the arctan(x) function (see Math.Mod in this repository). 
	Verify the results here: https://www.gigacalculator.com/calculators/arctan-calculator.php 
	Texts1.Mod is in https://github.com/hansklav/Oberon-REAL-IO
*)
	IMPORT Fonts, Texts, Texts1, Oberon, Math;

	VAR W: Texts.Writer;

	PROCEDURE Do*; 
		VAR x, rad, lim: REAL;  T: Texts.Text;
	BEGIN 
		Texts.SetFont(W, Fonts.This("Courier10.Fnt"));
		Texts.WriteString(W, "          x      arctan(x)");  Texts.WriteLn(W);
		lim := Math.pi / 2.0;  
		x := 0.0;  rad := Math.arctan(x);
		WHILE (rad <= lim) & (x <= 1.0E20) DO
			Texts1.WriteRealFix(W, x, 15, 3);  Texts1.WriteRealFix(W, rad, 10, 6); 
			Texts.WriteRealFix(W, x, 11, 3);  Texts.WriteRealFix(W, rad, 10, 6);  Texts.WriteLn(W);
			IF x < 0.1 THEN 
				x := x + 0.001
			ELSIF x < 1.0 THEN
				x := x + 0.01
			ELSIF x < 10.0 THEN
				x := x + 0.1
			ELSIF x < 100.0 THEN
				x := x + 1.0
			ELSE 
				x := x * 10.0
			END;  
			rad := Math.arctan(x)
		END;
		Texts.Append(Oberon.Log, W.buf)
	END Do;

BEGIN 
	Texts.OpenWriter(W)
END TestArctan.

TestArctan.Do
