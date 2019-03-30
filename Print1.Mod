MODULE Print1; (* IN Oberon *) (* Hans Klaver, 09-May-1999, 2019 *)
(** To execute mark this viewer with * and middle-click Print1.Me **)
	IMPORT In, Out := Out1;

	PROCEDURE Me*;
		VAR ch: CHAR;
	BEGIN 
		In.Open;  
		In.Char(ch);
		WHILE In.Done DO
			Out.Char(ch);
			In.Char(ch)
		END
	END Me;

BEGIN Out.Immediate(TRUE)
END Print1.Me*
